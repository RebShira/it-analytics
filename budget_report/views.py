from django.shortcuts import render
from it_analytics import data_interactions
from datetime import date
from io import BytesIO
import xlsxwriter
from django.http import HttpResponse


images = {
    '2002': '2002', '2006': '2006', '2007': '2007', '2014': '2014', '2016': '2016',
    '2017': '2017', '2018': '2018', '2020': '2020', '2021': '2021', '2022': '2022',
    '2023': '2023', '2025': '2025', '2221': '2221', '3001': '3001','3002': '3002',
    '3003': '3003', '3004': '3004', '3006': '3006', '3007': '3007', '3009': '3009',
    '3010': '3010', '3011': '3011', '3012': '3012', '1100': 'NHA','1300': 'NHA',
    '1400': 'NHA', '1502': 'NHA', '3001LG': 'NHA', '4220': 'NHA', '4235': 'NHA',
    '4237': 'NHA', '4295': 'NHA', '4296': 'NHA', '4297': 'NHA', '4298': 'NHA',
    '4299': 'NHA', '4301': 'NHA', '4320': '4320', '4330': '4330', '4331': '4331',
    '4339': 'NHA', '4344': 'NHA', '4399': 'NHA', '4999': 'NHA', '5003': 'NHA',
    '5164': 'NHA', '8003': 'NHA'
}


def detail(request, curramp, has_options='NONE'):

    budgetlines = data_interactions.return_dataset(ID=9, Format='JSON', Data=True, Amp=curramp)
    today = date.today()
    year = str(today.year)
    img = 'budget_report/' + images.get(curramp) + '.jpg'
    abbrev_amp = str(budgetlines[0].get('AMPDEPT'))[5:]

    context = {
    "amp": curramp,
    "budgetlines": budgetlines,
    "image": img,
    "ampdept": budgetlines[0].get('AMPDEPT'),
    "abbrev_amp": abbrev_amp,
    "mgrname": budgetlines[0].get('MGRNAME'),
    "dirname": budgetlines[0].get('DIRNAME'),
    "chiefname": budgetlines[0].get('CHIEFNAME'),
    "today": date.today(),
    "year": year,
    "etl": budgetlines[0].get('ETLDATE')}

    if request.method == 'GET':
        return render(request, 'budget_report/index.html', context)

    else:
        budgetlines_no_format = data_interactions.return_dataset(ID=16, Format='JSON', Data=True, Amp=curramp)
        context["budgetlines"] = budgetlines_no_format
        doctype = request.POST.getlist("doctype")
        if "excel" in doctype:
            response = HttpResponse(content_type="application/vnd.ms-excel")
            response['Content-Disposition'] = f'attachment; filename=BudgetActual - {curramp}.xlsx'
            xlsx_data = detail_to_excel(context)
            response.write(xlsx_data)
            return response
        else:
            return HttpResponse(doctype)


def detail_to_excel(context):

    # Initial Setup:
    output = BytesIO()
    workbook = xlsxwriter.Workbook(output)
    sheet = workbook.add_worksheet(context["amp"])

    # Formats:

    style_title1 = workbook.add_format(
        {
            'bold': True,
            'font_size': 16,
            'font_name': 'Arial'
        }
    )

    style_title2 = workbook.add_format(
        {
            'bold': True,
            'font_size': 14,
            'font_name': 'Arial'
        }
    )

    style_subtitle1 = workbook.add_format(
        {
            'font_size': 12,
            'font_name': 'Arial'
        }
    )

    style_subtitle2 = workbook.add_format(
        {
            'font_size': 10,
            'font_name': 'Arial'
        }
    )

    style_header = workbook.add_format(
        {
            'font_size': 10,
            'font_name': 'Times New Roman',
            'font_color': 'white',
            'bg_color': 'black',
            'bold': True,
            'align': 'center'
        }
    )

    style_data_text = workbook.add_format(
        {
            'font_size': 10,
            'font_name': 'Courier New',
            'align': 'left',
            'border': 1
        }
    )

    style_data_currency = workbook.add_format(
        {
            'font_size': 10,
            'font_name': 'Courier New',
            'num_format': '_($* #,##0.00_);_($* (#,##0.00);_($* "-"??_);_(@_)',
            'align': 'center',
            'border': 1
        }
    )

    style_data_percent = workbook.add_format(
        {
            'font_size': 10,
            'font_name': 'Courier New',
            # 'num_format': '0.00%',
            'num_format': '_(0.00%_);_((0.00%);_("-"??_);_(@_)',
            'align': 'center',
            'border': 1
        }
    )

    # Populate headers and column names:
    sheet.write(0, 0, "Budget vs Actual " + context["year"], style_title1)
    sheet.write(1, 0, context["ampdept"], style_title2)

    sheet.write(3, 0, "MANAGER", style_subtitle1)
    sheet.write(3, 1, context["mgrname"], style_subtitle1)
    sheet.write(4, 0, "DIRECTOR", style_subtitle1)
    sheet.write(4, 1, context["dirname"], style_subtitle1)
    sheet.write(5, 0, "CHIEF", style_subtitle1)
    sheet.write(5, 1, context["chiefname"], style_subtitle1)

    sheet.write(6, 0, "Data as of: ", style_subtitle2)
    sheet.write(6, 1, context["etl"], style_subtitle2)

    sheet.write(8, 0, "ACCOUNT CODE", style_header)
    sheet.write(8, 1, "ACCOUNT DESCRIPTION", style_header)
    sheet.write(8, 2, context["year"] + " ANNUAL BUDGET", style_header)
    sheet.write(8, 3, "MTD BUDGET", style_header)
    sheet.write(8, 4, "MTD ACTUAL", style_header)
    sheet.write(8, 5, "MTD VARIANCE", style_header)
    sheet.write(8, 6, "YTD BUDGET", style_header)
    sheet.write(8, 7, "YTD ACTUAL", style_header)
    sheet.write(8, 8, "YTD VARIANCE", style_header)
    sheet.write(8, 9, "AVAILABLE", style_header)
    sheet.write(8, 10, "PERCENT EXPENDED", style_header)

    # Write the data:
    row_start = 9
    col_start = 4
    col_end = 10
    curr_row = row_start
    for record in context["budgetlines"]:
        sheet.write(curr_row, 0, record["ACCT"], style_data_text)
        sheet.write(curr_row, 1, record["DESCRIPT"], style_data_text)
        sheet.write(curr_row, 2, record["TOTBUDAMT"], style_data_currency)
        sheet.write(curr_row, 3, record["MBUDAMT"], style_data_currency)
        sheet.write(curr_row, 4, record["MAMTA"], style_data_currency)
        sheet.write(curr_row, 5, record["MVARIANCE"], style_data_currency)
        sheet.write(curr_row, 6, record["YBUDAMT"], style_data_currency)
        sheet.write(curr_row, 7, record["YAMTA"], style_data_currency)
        sheet.write(curr_row, 8, record["YVARIANCE"], style_data_currency)
        sheet.write(curr_row, 9, record["AVAILABLE"], style_data_currency)
        sheet.write(curr_row, 10, record["PEREXP"], style_data_percent)
        curr_row += 1

    # Final touch-ups:
    sheet.set_column(0, 0, 15.5)
    sheet.set_column(1, 1, 60)
    sheet.set_column(2, 2, 20)
    sheet.set_column(3, 10, 20)
    sheet.hide_gridlines(2)

    # Close workbook and return IO Stream:
    workbook.close()
    xlsx_data = output.getvalue()
    return xlsx_data


def select(request, option_code):
    my_id = 0
    corrected_code = option_code.upper()
    if corrected_code == 'ALL':
        my_id = 11
    elif corrected_code == 'COCC':
        my_id = 12
    elif corrected_code == 'AMP':
        my_id = 13
    elif corrected_code == 'LIPH':
        my_id = 14
    elif corrected_code == 'RAD':
        my_id = 15
    else:
        pass
    today = date.today()
    year = str(today.year)
    options = data_interactions.return_dataset(ID=my_id, Format='JSON', Data=True)
    return render(request, 'budget_report/options.html', {'options': options, 'option_code': corrected_code, 'yeare': year})

