module Main exposing (Model, init, main, update, view)

import Browser
import FormatNumber exposing (format)
import FormatNumber.Locales exposing (Decimals(..), base)
import Html exposing (Html, b, button, div, hr, input, span, table, tbody, td, text, textarea, th, thead, tr)
import Html.Attributes exposing (attribute, class, value)
import Html.Events exposing (on, onClick, onInput, targetValue)
import Json.Decode as JD
import List.Extra as ListE



-- MAIN


main : Program () Model Msg
main =
    Browser.sandbox { init = init, update = update, view = view }



-- MODEL


type alias Course =
    { name : String
    , gradePoints : Float
    , creditsCounted : Float
    , creditsPassed : Float
    }


type alias Model =
    { courses : List Course
    , coursesJson : String
    }


init : Model
init =
    { courses = [], coursesJson = "" }



-- UPDATE


type Msg
    = LoadCourses
    | SetCoursesJson String
    | SetCourseName Int String
    | SetCourseGradePoints Int String
    | SetCourseCreditsCounted Int String
    | SetCourseCreditsPassed Int String
    | RemoveCourse Int
    | RemoveDuplicateCourses
    | AddCourse


type StatusError
    = BlankCoursesList
    | DuplicateCourses


update : Msg -> Model -> Model
update msg model =
    case msg of
        LoadCourses ->
            { model
                | courses =
                    Result.withDefault []
                        (JD.decodeString
                            (JD.list
                                (JD.map4 Course
                                    (JD.field "name" JD.string)
                                    (JD.field "gradePoints" JD.float)
                                    (JD.field "creditsCounted" JD.float)
                                    (JD.field "creditsPassed" JD.float)
                                )
                            )
                            model.coursesJson
                        )
                , coursesJson = ""
            }

        SetCoursesJson json ->
            { model | coursesJson = json }

        SetCourseName index name ->
            { model | courses = ListE.updateAt index (\course -> { course | name = name }) model.courses }

        SetCourseGradePoints index gradePoints ->
            { model | courses = ListE.updateAt index (\course -> { course | gradePoints = gradePoints |> String.toFloat |> Maybe.withDefault 0 }) model.courses }

        SetCourseCreditsCounted index creditsCounted ->
            { model | courses = ListE.updateAt index (\course -> { course | creditsCounted = creditsCounted |> String.toFloat |> Maybe.withDefault 0 }) model.courses }

        SetCourseCreditsPassed index creditsPassed ->
            { model | courses = ListE.updateAt index (\course -> { course | creditsPassed = creditsPassed |> String.toFloat |> Maybe.withDefault 0 }) model.courses }

        RemoveCourse index ->
            { model | courses = model.courses |> ListE.removeAt index }

        AddCourse ->
            { model | courses = Course "New Course" 0 0 0 :: model.courses }

        RemoveDuplicateCourses ->
            { model
                | courses =
                    model.courses
                        |> List.sortWith
                            (\courseA courseB ->
                                case compare courseA.gradePoints courseB.gradePoints of
                                    LT ->
                                        GT

                                    EQ ->
                                        EQ

                                    GT ->
                                        LT
                            )
                        |> ListE.uniqueBy (\course -> course.name)
            }


courseToHtml : Int -> Course -> Html Msg
courseToHtml index course =
    tr []
        [ td
            []
            [ text (index + 1 |> String.fromInt) ]
        , td
            []
            [ input
                [ class "form-control"
                , value course.name
                , on "blur" (JD.map (SetCourseName index) targetValue)
                ]
                []
            ]
        , td
            []
            [ input
                [ class "form-control"
                , value (course.gradePoints |> String.fromFloat)
                , on "blur" (JD.map (SetCourseGradePoints index) targetValue)
                ]
                []
            ]
        , td
            []
            [ input
                [ class "form-control"
                , value (course.creditsCounted |> String.fromFloat)
                , on "blur" (JD.map (SetCourseCreditsCounted index) targetValue)
                ]
                []
            ]
        , td
            []
            [ input
                [ class "form-control"
                , value (course.creditsPassed |> String.fromFloat)
                , on "blur" (JD.map (SetCourseCreditsPassed index) targetValue)
                ]
                []
            ]
        , td []
            [ button
                [ class "btn btn-danger btn-sm"
                , onClick (RemoveCourse index)
                ]
                [ text "Remove" ]
            ]
        ]


coursesToHtml : List Course -> Html Msg
coursesToHtml courses =
    div [ class "row mt-3" ]
        [ div [ class "col-sm" ]
            [ table
                [ class "table table-striped table-hover" ]
                [ thead []
                    [ tr []
                        [ th
                            [ attribute "scope" "col" ]
                            [ text "#" ]
                        , th
                            [ attribute "scope" "col" ]
                            [ text "Name" ]
                        , th
                            [ attribute "scope" "col" ]
                            [ text "Grade Points" ]
                        , th
                            [ attribute "scope" "col" ]
                            [ text "Credits Counted" ]
                        , th
                            [ attribute "scope" "col" ]
                            [ text "Credits Passed" ]
                        , th
                            [ attribute "scope" "col" ]
                            [ text "Actions" ]
                        ]
                    ]
                , tbody []
                    (List.indexedMap courseToHtml courses)
                ]
            ]
        ]


type alias Status =
    { cgpa : Float, totalCredits : Float, totalGradePoints : Float }


coursesToStatus : List Course -> Result StatusError Status
coursesToStatus courses =
    if courses |> List.isEmpty then
        Err BlankCoursesList

    else if courses |> ListE.allDifferentBy (\course -> course.name) |> not then
        Err DuplicateCourses

    else
        let
            ( totalCredits, totalGradePoints ) =
                List.foldl
                    (\course ( sumOfcredits, sumOfGradePoints ) ->
                        ( sumOfcredits + min course.creditsCounted course.creditsPassed
                        , sumOfGradePoints + course.gradePoints
                        )
                    )
                    ( 0, 0 )
                    courses

            cgpa =
                if totalCredits == 0 then
                    0

                else
                    totalGradePoints / totalCredits
        in
        Ok <| Status cgpa totalCredits totalGradePoints


statusToHtml : Result StatusError Status -> Html Msg
statusToHtml statusResult =
    case statusResult of
        Err DuplicateCourses ->
            div []
                [ div
                    [ class "alert alert-danger" ]
                    [ text "There are some duplicate courses in the list." ]
                , div
                    [ class "alert alert-warning mb-0" ]
                    [ text "One of the side-effects of 'Remove Duplicates' is that it'll sort the courses by their grade points. That's because it always keeps the course with the highest grade points, for which sorting is necessary." ]
                ]

        Err BlankCoursesList ->
            div
                [ class "alert alert-warning mb-0" ]
                [ text "The courses list is empty. Begin by adding some courses." ]

        Ok status ->
            div
                []
                [ b [] [ text "CGPA: " ]
                , span []
                    [ text (status.cgpa |> format { base | decimals = Exact 2 }) ]
                , b [ class "ml-3" ] [ text "Total Credits: " ]
                , span []
                    [ text (status.totalCredits |> format { base | decimals = Max 1 }) ]
                , b [ class "ml-3" ] [ text "Total Grade Points: " ]
                , span []
                    [ text (status.totalGradePoints |> format { base | decimals = Max 1 }) ]
                ]



-- VIEW


view : Model -> Html Msg
view model =
    let
        status =
            model.courses |> coursesToStatus

        statusHtml =
            status |> statusToHtml

        addCourseButton =
            button
                [ class "btn btn-outline-success"
                , onClick AddCourse
                ]
                [ text "Add Course" ]

        removeDuplicatesButton =
            if status == Err DuplicateCourses then
                button
                    [ class "btn btn-outline-danger ml-1"
                    , onClick RemoveDuplicateCourses
                    ]
                    [ text "Remove Duplicates" ]

            else
                text ""
    in
    div [ class "container" ]
        [ div
            [ class "row mt-3" ]
            [ div
                [ class "col-sm" ]
                [ div
                    [ class "d-flex flex-row justify-content-between align-items-start" ]
                    [ textarea
                        [ class "form-control"
                        , attribute "placeholder" "JSON"
                        , onInput SetCoursesJson
                        , value model.coursesJson
                        ]
                        []
                    , button
                        [ class "btn btn-outline-primary btn-sm ml-2"
                        , onClick LoadCourses
                        ]
                        [ text "Load" ]
                    ]
                ]
            ]
        , div [ class "row mt-3" ]
            [ div [ class "col-sm" ]
                [ hr
                    []
                    []
                , statusHtml
                ]
            ]
        , div [ class "row" ]
            [ div [ class "col-sm" ]
                [ hr [] []
                , addCourseButton
                , removeDuplicatesButton
                ]
            ]
        , coursesToHtml model.courses
        ]
