# import textract
# text = textract.process('input/gradesheet.pdf', method='pdfminer')
# print(text)

import PyPDF2
import re
import sys

file = open(sys.argv[-1], "rb")
reader = PyPDF2.PdfFileReader(file)

content = ''
for i in range(reader.numPages):
    page_content = reader.getPage(i).extractText().replace(
        '!!!!!!!!', '').replace('Developed & Maintained By NSU IT Dept.', '')
    content += page_content[0:page_content.find(
        "Online Portal | North South University")]


def grade_points(grade):
    if grade == 'A':
        return 4
    elif grade == 'A-':
        return 3.7
    elif grade == 'B+':
        return 3.3
    elif grade == 'B':
        return 3.0
    elif grade == 'B-':
        return 2.7
    elif grade == 'C+':
        return 2.3
    elif grade == 'C':
        return 2.0
    elif grade == 'C-':
        return 1.7
    elif grade == 'D+':
        return 1.3
    elif grade == 'D':
        return 1.0
    else:
        return 0


def process_semester(semester_season, content):
    units = re.split('(3.00|1.50|1.00|0.00)', content)

    print(units)

    total_credits = 0
    total_weighted_credits = 0
    courses = []
    course_code = ''
    course_credits = 0
    course_grade = ''
    credits_count = 0
    credits_passed = 0
    semester_year = ''

    for i in range(len(units)):
        local_index = i % 6

        if local_index == 0:
            segments = units[i].strip().split('\n')
            if (len(segments) == 2):
                semester_year = segments[0]
            course_code = segments[-1]
        elif local_index == 1:
            course_credits = float(units[i])
        elif local_index == 2:
            course_grade = units[i].strip().split('\n')[-1]
        elif local_index == 3:
            credits_count = float(units[i])
        elif local_index == 5:
            credits_passed = float(units[i])

            if credits_passed > 0 and credits_count > 0:
                total_credits += credits_passed
                total_weighted_credits += credits_passed * \
                    grade_points(course_grade)

            courses.append({
                "code": course_code,
                "credits": course_credits,
                "grade": course_grade,
                "credits_count": credits_count,
                "credits_passed": credits_passed,
                "weighted_credits": credits_passed * grade_points(course_grade)})

    print("TGPA: %.2f (%s %s)" % (total_weighted_credits /
                                  total_credits, semester_season, semester_year))

    return {"courses": courses, "season": semester_season, "year": semester_year}


def insert_course(course, courses):
    if course['credits_passed'] > 0 and course['credits_count'] > 0:
        if course['code'] in courses and courses[course['code']]['weighted_credits'] < course['weighted_credits']:
            courses[course['code']] = {
                'weighted_credits': course['weighted_credits'],
                'credits': course['credits_count']
            }
        else:
            courses[course['code']] = {
                'weighted_credits': course['weighted_credits'],
                'credits': course['credits_count']
            }

    return courses


total_weighted_credits = 0
total_credits = 0

units = re.split('(Summer|Spring|Fall)', content)[1:]
courses = {}
for i in range(len(units)):
    if (units[i] == "Spring" or units[i] == "Summer" or units[i] == "Fall") and len(units) != i + 1:
        semester_info = process_semester(units[i], units[i + 1])
        for course in semester_info['courses']:
            courses = insert_course(course, courses)

# courses = insert_course(
#     {'code': 'CSE115', 'weighted_credits': 12, 'credits_passed': 3, 'credits_count': 3}, courses)
# courses = insert_course(
#     {'code': 'EEE141', 'weighted_credits': 12, 'credits_passed': 3, 'credits_count': 3}, courses)
# courses = insert_course(
#     {'code': 'EEE452', 'weighted_credits': 3 * 2, 'credits_passed': 3, 'credits_count': 3}, courses)
# courses = insert_course(
#     {'code': 'PHI101', 'weighted_credits': 3 * 2.7, 'credits_passed': 3, 'credits_count': 3}, courses)
del courses['PHI101']
# courses = insert_course(
# {'code': 'CSE115L', 'weighted_credits': 4, 'credits_passed': 1, 'credits_count': 1}, courses)

# courses = insert_course(
#     {'code': 'CSE327', 'weighted_credits': 12, 'credits_passed': 3, 'credits_count': 3}, courses)
# courses = insert_course(
#     {'code': 'BIO103', 'weighted_credits': 3 * 3.7, 'credits_passed': 3, 'credits_count': 3}, courses)
# courses = insert_course(
#     {'code': 'MAT250', 'weighted_credits': 3 * 3, 'credits_passed': 3, 'credits_count': 3}, courses)
# courses = insert_course(
#     {'code': 'CSE499B', 'weighted_credits': 1.5 * 4, 'credits_passed': 1.5, 'credits_count': 1.5}, courses)
# courses = insert_course(
#     {'code': 'MAT130', 'weighted_credits': 12, 'credits_passed': 3, 'credits_count': 3}, courses)

courses = insert_course(
    {'code': 'BIO103', 'weighted_credits': 9, 'credits_passed': 3, 'credits_count': 3}, courses)
courses = insert_course(
    {'code': 'BIO103L', 'weighted_credits': 3, 'credits_passed': 1, 'credits_count': 1}, courses)
courses = insert_course(
    {'code': 'CSE115L', 'weighted_credits': 3, 'credits_passed': 1, 'credits_count': 1}, courses)
courses = insert_course(
    {'code': 'CSE499B', 'weighted_credits': 1.5 * 3, 'credits_passed': 1.5, 'credits_count': 1.5}, courses)
courses = insert_course(
    {'code': 'ENG103', 'weighted_credits': 9, 'credits_passed': 3, 'credits_count': 3}, courses)
courses = insert_course(
    {'code': 'ENG111', 'weighted_credits': 9, 'credits_passed': 3, 'credits_count': 3}, courses)
courses = insert_course(
    {'code': 'HIS102', 'weighted_credits': 9, 'credits_passed': 3, 'credits_count': 3}, courses)
courses = insert_course(
    {'code': 'MAT120', 'weighted_credits': 9, 'credits_passed': 3, 'credits_count': 3}, courses)
courses = insert_course(
    {'code': 'PHY108L', 'weighted_credits': 3, 'credits_passed': 1, 'credits_count': 1}, courses)
courses = insert_course(
    {'code': 'POL101', 'weighted_credits': 9, 'credits_passed': 3, 'credits_count': 3}, courses)

for k, v in courses.items():
    print("%s %.2f" % (k, v['weighted_credits']))
    total_weighted_credits += v['weighted_credits']
    total_credits += v['credits']

print("CGPA: %.3f" % (total_weighted_credits / total_credits))
