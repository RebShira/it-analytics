import settings
import numpy as np
import pandas as pd
import data_interactions as di
from io import BytesIO
import xlsxwriter as xl
from datetime import datetime

DEFAULT_PATH = "C:\\Users\\ajaman\\Desktop\\"


def load_adp():
    adp_doc = str(settings.BASE_DIR) + "\\static\\uploads\\ADP.xlsx"
    adp_pd = pd.read_excel(adp_doc)
    adp = np.array(adp_pd)
    departments = di.return_dataset(ID=48, Format="numpy", Data=True)
    di.crud("TRUNCATE TABLE dbo.employee_employees_ADP")

    # Loop through new employee list and insert into table.

    emp_id = 1
    for emp in adp:
        last_name = str(emp[0]).replace("'", "")
        first_name = str(emp[1]).replace("'", "")
        job_title = str(emp[2]).replace("'", "")
        hire_date = emp[5]
        # Get foreign key to department table:
        fk_department = 0
        for dept in departments:
            if dept[1] == str(emp[4]).upper():
                fk_department = dept[0]
        sql = f"INSERT INTO dbo.employee_employees_ADP (id, fk_department, last_name, first_name, job_title, hire_date) " \
              f"VALUES ({emp_id}, {fk_department}, '{last_name}', '{first_name}', '{job_title}', '{hire_date}')"
        di.crud(sql)
        emp_id += 1


def load_bamboo():
    bamboo_doc = str(settings.BASE_DIR) + "\\static\\uploads\\BAMBOO.xlsx"
    bamboo_pd = pd.read_excel(bamboo_doc, sheet_name="BAMBOO")
    bamboo = np.array(bamboo_pd)
    departments = di.return_dataset(ID=50, Format="numpy", Data=True)
    di.crud("TRUNCATE TABLE dbo.employee_employees_BAMBOO")

    # Extract the needed columns of the employee data, and make it unique...

    bamboo = np.delete(bamboo, obj=4, axis=1)
    bamboo = np.delete(bamboo, obj=4, axis=1)
    bamboo = np.delete(bamboo, obj=4, axis=1)
    bamboo = np.delete(bamboo, obj=4, axis=1)
    bamboo = np.delete(bamboo, obj=6, axis=1)
    bamboo = np.delete(bamboo, obj=6, axis=1)
    bamboo = np.delete(bamboo, obj=6, axis=1)
    bamboo = np.delete(bamboo, obj=6, axis=1)
    bamboo = np.delete(bamboo, obj=6, axis=1)
    bamboo = np.delete(bamboo, obj=6, axis=1)
    bamboo = np.delete(bamboo, obj=6, axis=1)
    bamboo = np.delete(bamboo, obj=6, axis=1)

    # Loop through new employee list and insert into table.
    # Keep track of previous employee numbers, so as not to insert duplicate values.

    curr_id = 0
    for emp in bamboo:
        if emp[0] != curr_id:
            curr_id = emp[0]
            last_name = str(emp[1]).replace("'", "")
            first_name = str(emp[2]).replace("'", "")
            # Get foreign key to department table:
            fk_department = 0
            for dept in departments:
                if dept[1] == emp[4]:
                    fk_department = dept[0]
            hire_date = str(emp[3])
            job_tite = str(emp[5]).replace("'", "")
            sql = f"INSERT INTO dbo.employee_employees_BAMBOO (id, fk_department, last_name, first_name, " \
                  f"job_title, hire_date) " \
                  f"VALUES ({curr_id}, {fk_department}, '{last_name}', '{first_name}', '{job_tite}', '{hire_date}')"
            di.crud(sql)


def employee_report_by_department(source):
    # function "constants":

    col_width_small = 10
    col_width_medium = 20
    col_width_large = 35

    # Get data from datastore, depending upon passed argument
    datastore_id = 0
    date = datetime.now()
    format_date = date.strftime("%A, %B %d, %Y")
    if source == "ADP":
        datastore_id = 51
        app = "ADP"
    else:
        datastore_id = 52
        app = "BAMBOO"

    test_path = f"C:\\Users\\ajaman\\Desktop\\EmployeeByDepartment-{app}.xlsx"

    report_data = di.return_dataset(ID=datastore_id, Format="NUMPY", Data=True)

    # <<< Next 2 lines commented out, until this gets incorporated onto Django Application. >>>
    #
    # output = BytesIO()
    # workbook = xl.Workbook(output)
    workbook = xl.Workbook(test_path)

    # Formats:

    if source != "ADP":
        style_title = workbook.add_format(
            {
                'bold': False,
                'font_size': 20,
                'font_name': 'Times New Roman',
                'bg_color': '#A2E9F3'
            }
        )

        style_subtitle = workbook.add_format(
            {
                'bold': False,
                'font_size': 14,
                'font_name': 'Times New Roman',
                'bg_color': '#A2E9F3'
            }
        )

    else:
        style_title = workbook.add_format(
            {
                'bold': False,
                'font_size': 20,
                'font_name': 'Times New Roman',
                'bg_color': '#F3ABA2'
            }
        )

        style_subtitle = workbook.add_format(
            {
                'bold': False,
                'font_size': 14,
                'font_name': 'Times New Roman',
                'bg_color': '#F3ABA2'
            }
        )

    style_column = workbook.add_format(
        {
            'bold': True,
            'font_size': 11,
            'font_name': 'Times New Roman',
            'font_color': '#FFFFFF',
            'bg_color': 'black'
        }
    )

    style_underline = workbook.add_format(
        {
            'bold': False,
            'font_size': 11,
            'font_name': 'Calibri',
            'bottom': True
        }
    )

    style_detail_invisible = workbook.add_format(
        {
            'bold': False,
            'font_size': 11,
            'font_name': 'Calibri',
            'font_color': '#FFFFFF'
        }
    )

    style_detail = workbook.add_format(
        {
            'bold': False,
            'font_size': 11,
            'font_name': 'Calibri',
            'font_color': 'black'
        }
    )

    style_total = workbook.add_format(
        {
            'bold': False,
            'font_size': 12,
            'font_name': 'Calibri',
            'font_color': 'black',
            'italic': True
        }
    )

    # Initialize worksheet
    worksheet = workbook.add_worksheet()
    worksheet.name = app
    worksheet.hide_gridlines()

    # Set up header content
    worksheet.write("A1", f"NHA Employee List ({app})", style_title)
    worksheet.write("B1", "", style_title)
    worksheet.write("C1", "", style_title)
    worksheet.write("A2", f"As of: {format_date}", style_subtitle)
    worksheet.write("B2", "", style_subtitle)
    worksheet.write("C2", "", style_subtitle)

    worksheet.set_column(0, 0, col_width_large)
    worksheet.set_column(1, 3, col_width_medium)
    worksheet.set_column(4, 4, col_width_large)
    worksheet.set_column(5, 5, col_width_small)

    worksheet.write("A4", "Department", style_column)
    worksheet.write("B4", "Manager", style_column)
    worksheet.write("C4", "Last Name", style_column)
    worksheet.write("D4", "First Name", style_column)
    worksheet.write("E4", "Job Title", style_column)
    worksheet.write("F4", "Hire Date", style_column)

    # Write the data

    curr_row = 4
    last_dept = "none"
    emp_count = 0
    group_start = 0

    for line in report_data:
        curr_dept = line[0]
        manager = line[1]
        last_name = line[2]
        first_name = line[3]
        job_title = line[4]
        hire_date = line[5]

        if curr_dept != last_dept:
            worksheet.write(curr_row, 0, curr_dept, style_underline)
            worksheet.write(curr_row, 1, manager, style_underline)
            if last_dept == "none":
                group_start = curr_row + 1
            else:
                for i in range(group_start, curr_row):
                    worksheet.set_row(i, None, None, {'level': 1})
                group_start = curr_row + 1
            last_dept = curr_dept
        else:
            worksheet.write(curr_row, 0, curr_dept, style_detail_invisible)
            worksheet.write(curr_row, 1, manager, style_detail_invisible)
            worksheet.write(curr_row, 2, last_name, style_detail)
            worksheet.write(curr_row, 3, first_name, style_detail)
            worksheet.write(curr_row, 4, job_title, style_detail)
            worksheet.write(curr_row, 5, hire_date, style_detail)
            emp_count += 1
        curr_row += 1

    curr_row += 1
    worksheet.write(curr_row, 4, "Total Full-Time Employees:")
    worksheet.write(curr_row, 5, str(emp_count))

    # And now, for some metrics hopefully...
    # TODO:

    workbook.close()


def adp_bamboo_compare():
    """
    Compares ADP and BAMBOO employee files, checks for discrepancies.
    """

    width_divide = 3
    width_small = 6
    width_medium = 15
    width_large = 22
    width_xl = 40
    width_xxl = 65


    # Get the datasets:
    adp_doc = str(settings.BASE_DIR) + "\\static\\uploads\\ADP.xlsx"
    bamboo_doc = str(settings.BASE_DIR) + "\\static\\uploads\\BAMBOO.xlsx"

    adp = pd.read_excel(adp_doc, converters={"Home Department Code": str})
    bamboo = pd.read_excel(bamboo_doc, sheet_name="BAMBOO")

    # Start build on output array.
    # First, get unique names and identity columns from BAMBOO, built with last 4 SSN and hire date concatenated.

    compare_columns = {"EID": [],  # Unique identifier for record.
                       "EMPID": [], "LNAME": [], "FNAME": [], "HIRE_DATE": [],
                       "BAMBOO_DEPT": [], "BAMBOO_TITLE": [], "BAMBOO_RATE": [], "BAMBOO_HOURS": [], "BAMBOO_UNION": []}
    compare = pd.DataFrame(compare_columns)

    for emp in bamboo.index:
        emp_id = bamboo["Employee #"][emp]
        l_name = bamboo["Last Name"][emp]
        f_name = bamboo["First Name"][emp]
        hire_date = str(bamboo["Hire Date"][emp])
        hire_date = hire_date[5:7] + "/" + hire_date[8:10] + "/" + hire_date[:4]
        eid = hire_date.replace("/", "")
        if len(str(bamboo["SSN"][emp])) == 11:
            eid = eid + "-" + str(bamboo["SSN"][emp])[7:]
        bamboo_dept = str(bamboo["Division"][emp])
        bamboo_title = str(bamboo["Job Title"][emp])
        bamboo_rate = str(bamboo["ADP Pay Rate"][emp])
        bamboo_hrs = str(bamboo["Number of Hours Worked"][emp])
        bamboo_union = str(bamboo["Union"][emp]).upper()
        if eid not in compare["EID"]:
            add_on = [eid, emp_id, l_name, f_name, hire_date,
                      bamboo_dept, bamboo_title, bamboo_rate, bamboo_hrs, bamboo_union]
            compare.loc[len(compare.index)] = add_on

    # Add the same id column to ADP, as a basis for matching and comparing.
    adp["EID"] = ""
    for emp in adp.index:
        hire_date = str(adp["Hire Date"][emp])
        hire_date = hire_date[5:7] + "/" + hire_date[8:10] + "/" + hire_date[:4]
        eid = hire_date.replace("/", "") + "-" + adp["Tax ID (SSN)"][emp][7:]
        adp.loc[emp, "EID"] = eid

    # Add the rest of the columns to compare and populate.
    compare["ADP_DEPT"] = ""
    compare["ADP_DEPT_NAME"] = ""
    compare["ADP_TITLE"] = ""
    compare["ADP_RATE"] = ""
    compare["ADP_HOURS"] = ""
    compare["ADP_SALARY"] = ""
    compare["ADP_UNION"] = ""

    for emp in compare.index:
        if "-" not in compare["EID"][emp]:
            compare.loc[emp, "ADP_DEPT_NAME"] = "## MISSING SSN IN BAMBOO ##"
        else:
            eid = compare["EID"][emp]
            adp_match = adp.loc[adp["EID"] == eid]
            if len(adp_match.index) == 0:
                compare.loc[emp, "ADP_DEPT_NAME"] = "## NO MATCH IN ADP ##"
            else:
                pass
                for idx in adp_match.index:
                    compare.loc[emp, "ADP_DEPT"] = str(adp_match.loc[idx, "Home Department Code"])
                    compare.loc[emp, "ADP_DEPT_NAME"] = str(adp_match.loc[idx, "Home Department Description"])
                    compare.loc[emp, "ADP_TITLE"] = adp_match.loc[idx, "Job Title Description"]
                    compare.loc[emp, "ADP_RATE"] = str(adp_match.loc[idx, "Regular Pay Rate Amount"])
                    compare.loc[emp, "ADP_HOURS"] = str(adp_match.loc[idx, "Standard Hours"])
                    compare.loc[emp, "ADP_SALARY"] = str(adp_match.loc[idx, "Annual Salary"])
                    compare.loc[emp, "ADP_UNION"] = str(adp_match.loc[idx, "Union Code Description"]).upper()

    compare.fillna("")
    # Add comparison fields, and do the comparisons.
    compare["DIFF_DEPT"] = ""   # Watch (in order): "##" ADP DEPT NAMEs, 3001LG and leading zeros.
    compare["DIFF_TITLE"] = ""
    compare["DIFF_RATE"] = ""
    compare["DIFF_HOURS"] = ""
    compare["DIFF_UNION"] = ""

    for idx in compare.index:
        if "##" not in compare["ADP_DEPT_NAME"][idx]:

            # Department:
            dept_adp = compare.loc[idx, "ADP_DEPT"][2:]
            dept_bamboo = compare.loc[idx, "BAMBOO_DEPT"]
            if dept_adp != dept_bamboo:
                if dept_adp != "3001" and dept_bamboo != "3001LG":
                    compare.loc[idx, "DIFF_DEPT"] = "X"

            # Title:
            title_adp = compare.loc[idx, "ADP_TITLE"]
            title_bamboo = compare.loc[idx, "BAMBOO_TITLE"]
            if title_adp != title_bamboo:
                compare.loc[idx, "DIFF_TITLE"] = "X"

            # Rate:
            rate_adp = compare.loc[idx, "ADP_RATE"]
            rate_bamboo = compare.loc[idx, "BAMBOO_RATE"]
            if rate_adp != rate_bamboo:
                compare.loc[idx, "DIFF_RATE"] = "X"

            # Hours:
            hours_adp = str(compare.loc[idx, "ADP_HOURS"]).replace("nan", "")
            hours_bamboo = str(compare.loc[idx, "BAMBOO_HOURS"]).replace("nan", "")
            if hours_adp != hours_bamboo:
                compare.loc[idx, "DIFF_HOURS"] = "X"

            # Union:
            union_adp = compare.loc[idx, "ADP_UNION"]
            union_bamboo = compare.loc[idx, "BAMBOO_UNION"]
            if union_adp != union_bamboo:
                compare.loc[idx, "DIFF_UNION"] = "X"

    # Finally: Build the spreadsheet.

    compxls = xl.Workbook(DEFAULT_PATH + "compare.xlsx")
    worksheet = compxls.add_worksheet(name="Compare")

    # Excel Styles:

    style_header = compxls.add_format(
        {
            'bold': True,
            'font_name': 'Calibri',
            'font_size': 11
        }
    )

    style_divide_black = compxls.add_format(
        {
            'bg_color': 'black'
        }
    )

    style_divide_blue = compxls.add_format(
        {
            'bg_color': '#1757E4'
        }
    )

    style_detail = compxls.add_format(
        {
            'bold': False,
            'font_name': 'Calibri',
            'font_size': '11'
        }
    )

    style_error = compxls.add_format(
        {
            'bold': False,
            'font_name': 'console',
            'font_size': 11,
            'font_color': 'red'
        }
    )

    # Populate spreadsheet layout and data.

    worksheet.write("A1", "EMPID", style_header)
    worksheet.write("B1", "LNAME", style_header)
    worksheet.write("C1", "FNAME", style_header)
    worksheet.write("D1", "HIRE DATE", style_header)
    worksheet.write("E1", "", style_divide_black)
    worksheet.write("F1", "ADP DEPT", style_header)
    worksheet.write("G1", "ADP DEPT NAME", style_header)
    worksheet.write("H1", "", style_divide_blue)
    worksheet.write("I1", "BAMBOO DEPT", style_header)
    worksheet.write("J1", "DIFFERENCE", style_header)
    worksheet.write("K1", "", style_divide_black)
    worksheet.write("L1", "ADP TITLE", style_header)
    worksheet.write("M1", "", style_divide_blue)
    worksheet.write("N1", "BAMBOO TITLE", style_header)
    worksheet.write("O1", "DIFFERENCE", style_header)
    worksheet.write("P1", "", style_divide_black)
    worksheet.write("Q1", "ADP RATE", style_header)
    worksheet.write("R1", "ADP HOURS", style_header)
    worksheet.write("S1", "ADP SALARY", style_header)
    worksheet.write("T1", "", style_divide_blue)
    worksheet.write("U1", "BAMBOO RATE", style_header)
    worksheet.write("V1", "BAMBOO HRS", style_header)
    worksheet.write("W1", "", style_divide_blue)
    worksheet.write("X1", "DIFF IN RATE", style_header)
    worksheet.write("Y1", "DIFF IN HRS", style_header)
    worksheet.write("Z1", "", style_divide_black)
    worksheet.write("AA1", "ADP UNION", style_header)
    worksheet.write("AB1", "", style_divide_blue)
    worksheet.write("AC1", "BAMBOO UNION", style_header)
    worksheet.write("AD1", "DIFF", style_header)
    worksheet.write("AE1", "", style_divide_black)

    # Data:

    is_error = False
    curr_row = 1
    for idx in compare.index:

        worksheet.write(curr_row, 0, compare.loc[idx, "EMPID"], style_detail)
        worksheet.write(curr_row, 1, compare.loc[idx, "LNAME"], style_detail)
        worksheet.write(curr_row, 2, compare.loc[idx, "FNAME"], style_detail)
        worksheet.write(curr_row, 3, compare.loc[idx, "HIRE_DATE"], style_detail)
        worksheet.write(curr_row, 8, compare.loc[idx, "BAMBOO_DEPT"], style_detail)
        worksheet.write(curr_row, 13, compare.loc[idx, "BAMBOO_TITLE"], style_detail)
        worksheet.write(curr_row, 20, compare.loc[idx, "BAMBOO_RATE"], style_detail)
        worksheet.write(curr_row, 21, compare.loc[idx, "BAMBOO_HOURS"], style_detail)
        worksheet.write(curr_row, 28, compare.loc[idx, "BAMBOO_UNION"], style_detail)

        worksheet.write(curr_row, 4, "", style_divide_black)
        worksheet.write(curr_row, 7, "", style_divide_blue)
        worksheet.write(curr_row, 10, "", style_divide_black)
        worksheet.write(curr_row, 12, "", style_divide_blue)
        worksheet.write(curr_row, 15, "", style_divide_black)
        worksheet.write(curr_row, 19, "", style_divide_blue)
        worksheet.write(curr_row, 22, "", style_divide_blue)
        worksheet.write(curr_row, 25, "", style_divide_black)
        worksheet.write(curr_row, 27, "", style_divide_blue)
        worksheet.write(curr_row, 30, "", style_divide_black)

        if "##" in compare.loc[idx, "ADP_DEPT_NAME"]:
            worksheet.write(curr_row, 6, compare.loc[idx, "ADP_DEPT_NAME"], style_error)
            is_error = True

        if is_error:
            worksheet.write(curr_row, 9, "X", style_detail)
            worksheet.write(curr_row, 14, "X", style_detail)
            worksheet.write(curr_row, 23, "X", style_detail)
            worksheet.write(curr_row, 24, "X", style_detail)
            worksheet.write(curr_row, 29, "X", style_detail)
        else:
            worksheet.write(curr_row, 5, compare.loc[idx, "ADP_DEPT"], style_detail)
            worksheet.write(curr_row, 6, compare.loc[idx, "ADP_DEPT_NAME"], style_detail)
            worksheet.write(curr_row, 9, compare.loc[idx, "DIFF_DEPT"], style_detail)
            worksheet.write(curr_row, 11, compare.loc[idx, "ADP_TITLE"], style_detail)
            worksheet.write(curr_row, 14, compare.loc[idx, "DIFF_TITLE"], style_detail)
            worksheet.write(curr_row, 16, compare.loc[idx, "ADP_RATE"], style_detail)
            if str(compare.loc[idx, "ADP_HOURS"]) == "nan" or len(str(compare.loc[idx, "ADP_HOURS"])) == 0:
                worksheet.write(curr_row, 17, "", style_detail)
            else:
                worksheet.write(curr_row, 17, compare.loc[idx, "ADP_HOURS"], style_detail)
            worksheet.write(curr_row, 18, compare.loc[idx, "ADP_SALARY"], style_detail)
            worksheet.write(curr_row, 23, compare.loc[idx, "DIFF_RATE"], style_detail)
            worksheet.write(curr_row, 24, compare.loc[idx, "DIFF_HOURS"], style_detail)
            worksheet.write(curr_row, 26, compare.loc[idx, "ADP_UNION"], style_detail)
            worksheet.write(curr_row, 29, compare.loc[idx, "DIFF_UNION"], style_detail)

            # worksheet.write(curr_row, 24, "X", style_detail)

        is_error = False
        curr_row += 1

    # Finish & close:

    worksheet.set_column("A:A", width_small)
    worksheet.set_column("B:B", width_medium)
    worksheet.set_column("C:C", width_medium)
    worksheet.set_column("D:D", width_medium)
    worksheet.set_column("G:G", width_xl)
    worksheet.set_column("I:I", width_medium)
    worksheet.set_column("J:J", width_medium)
    worksheet.set_column("L:L", width_xxl)
    worksheet.set_column("N:N", width_xxl)
    worksheet.set_column("O:O", width_medium)
    worksheet.set_column("Q:S", width_medium)
    worksheet.set_column("U:V", width_medium)
    worksheet.set_column("X:Y", width_medium)
    worksheet.set_column("AA:AA", width_large)
    worksheet.set_column("AC:AC", width_large)

    worksheet.set_column("E:E", width_divide)
    worksheet.set_column("H:H", width_divide)
    worksheet.set_column("K:K", width_divide)
    worksheet.set_column("M:M", width_divide)
    worksheet.set_column("P:P", width_divide)
    worksheet.set_column("T:T", width_divide)
    worksheet.set_column("W:W", width_divide)
    worksheet.set_column("Z:Z", width_divide)
    worksheet.set_column("AB:AB", width_divide)
    worksheet.set_column("AE:AE", width_divide)
    compxls.close()
    # compare.to_excel("C:\\Users\\ajaman\\Desktop\\compare.xlsx")


adp_bamboo_compare()







