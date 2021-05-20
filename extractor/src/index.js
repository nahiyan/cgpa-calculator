const tables = document.querySelectorAll('table')
const coreCourses = tables[3]
const gedCourses = tables[4]
const openElectiveCourses = tables[5]
const nonCreditCourses = tables[6]
const openElective2Courses = tables[7]

function parseCoursesTable (element) {
  const courses = []

  element.querySelectorAll('tbody tr').forEach(function (row) {
    const cells = row.querySelectorAll('td')

    if (cells.length === 0) { return }

    courses.push({
      name: cells[0].innerHTML,
      gradePoints: parseFloat(cells[4].innerHTML),
      creditsCounted: parseFloat(cells[5].innerHTML),
      creditsPassed: parseFloat(cells[6].innerHTML)
    })
  })

  return courses
}

console.log(JSON.stringify(parseCoursesTable(coreCourses).concat(parseCoursesTable(gedCourses)).concat(parseCoursesTable(openElectiveCourses)).concat(parseCoursesTable(nonCreditCourses)).concat(parseCoursesTable(openElective2Courses))))
