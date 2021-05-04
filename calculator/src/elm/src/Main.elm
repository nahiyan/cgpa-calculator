module Main exposing (Model, init, main, update, view)

import Browser
import Debug exposing (log)
import FormatNumber exposing (format)
import FormatNumber.Locales exposing (Decimals(..), base)
import Html exposing (Html, b, button, div, hr, input, span, table, tbody, td, text, textarea, th, thead, tr)
import Html.Attributes exposing (attribute, class, value)
import Html.Events exposing (onClick, onInput)
import Json.Decode as JD
import List.Extra exposing (removeAt, updateAt)



-- MAIN


main : Program () Model Msg
main =
    Browser.sandbox { init = init, update = update, view = view }



-- MODEL


type alias Course =
    { name : String
    , title : String
    , credits : Float
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
    | SetCourseTitle Int String
    | SetCourseCredits Int String
    | SetCourseGradePoints Int String
    | SetCourseCreditsCounted Int String
    | SetCourseCreditsPassed Int String
    | RemoveCourse Int
    | AddCourse


update : Msg -> Model -> Model
update msg model =
    case msg of
        LoadCourses ->
            { model
                | courses =
                    Result.withDefault []
                        (JD.decodeString
                            (JD.list
                                (JD.map6 Course
                                    (JD.field "name" JD.string)
                                    (JD.field "title" JD.string)
                                    (JD.field "credits" JD.float)
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
            { model | courses = updateAt index (\course -> { course | name = name }) model.courses }

        SetCourseTitle index title ->
            { model | courses = updateAt index (\course -> { course | title = title }) model.courses }

        SetCourseCredits index credits ->
            { model | courses = updateAt index (\course -> { course | credits = credits |> String.toFloat |> Maybe.withDefault 0 }) model.courses }

        SetCourseGradePoints index gradePoints ->
            { model | courses = updateAt index (\course -> { course | gradePoints = gradePoints |> String.toFloat |> Maybe.withDefault 0 }) model.courses }

        SetCourseCreditsCounted index creditsCounted ->
            { model | courses = updateAt index (\course -> { course | creditsCounted = creditsCounted |> String.toFloat |> Maybe.withDefault 0 }) model.courses }

        SetCourseCreditsPassed index creditsPassed ->
            { model | courses = updateAt index (\course -> { course | creditsPassed = creditsPassed |> String.toFloat |> Maybe.withDefault 0 }) model.courses }

        RemoveCourse index ->
            { model | courses = model.courses |> removeAt index }

        AddCourse ->
            { model | courses = Course "New Course" "Course Title" 0 0 0 0 :: model.courses }


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
                , onInput (SetCourseName index)
                ]
                []
            ]
        , td
            []
            [ input
                [ class "form-control"
                , value course.title
                , onInput (SetCourseTitle index)
                ]
                []
            ]
        , td
            []
            [ input
                [ class "form-control"
                , value (course.credits |> String.fromFloat)
                , onInput (SetCourseCredits index)
                ]
                []
            ]
        , td
            []
            [ input
                [ class "form-control"
                , value (course.gradePoints |> String.fromFloat)
                , onInput (SetCourseGradePoints index)
                ]
                []
            ]
        , td
            []
            [ input
                [ class "form-control"
                , value (course.creditsCounted |> String.fromFloat)
                , onInput (SetCourseCreditsCounted index)
                ]
                []
            ]
        , td
            []
            [ input
                [ class "form-control"
                , value (course.creditsPassed |> String.fromFloat)
                , onInput (SetCourseCreditsPassed index)
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
                            [ text "Title" ]
                        , th
                            [ attribute "scope" "col" ]
                            [ text "Credits" ]
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


coursesToCgpa : List Course -> Status
coursesToCgpa courses =
    if courses |> List.isEmpty then
        Status 0 0 0

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
        Status cgpa totalCredits totalGradePoints


statusToHtml : Status -> Html Msg
statusToHtml status =
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
                , model.courses |> coursesToCgpa |> statusToHtml
                ]
            ]
        , div [ class "row mt-3" ]
            [ div [ class "col-sm" ]
                [ hr
                    []
                    []
                , button
                    [ class "btn btn-outline-success"
                    , onClick AddCourse
                    ]
                    [ text "Add Course" ]
                ]
            ]
        , coursesToHtml model.courses
        ]
