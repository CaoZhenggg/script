#!/usr/bin/env python
# _*_ coding: utf-8 _*_
# Author: CaoZheng
# Date: 2017/11/10


from __future__ import print_function
import sys
reload(sys)
sys.setdefaultencoding('utf8')
import os
import xlsxwriter


diff_file = sys.argv[1]

if os.path.exists('/var/ftp/pub/diff_list.xlsx'):
    os.remove('/var/ftp/pub/diff_list.xlsx')

workbook = xlsxwriter.Workbook('/var/ftp/pub/diff_list.xlsx')

# format
fmt_url = workbook.add_format({'left': True, 'font_name': 'calibri' })
fmt_name = workbook.add_format({'center_across': True})

# worksheet
worksheet = workbook.add_worksheet()
worksheet.set_column('A:A', 140)
worksheet.set_column('B:B', 10)

with open(diff_file, 'r') as f:
    diff_line = list(line.split() for line in f.readlines())

    row = 0
    col = 0

    for url, name in (diff_line):
        worksheet.write_string(row, col, url, fmt_url)
        worksheet.write(row, col + 1, name, fmt_name)
        row += 1

workbook.close()

print('表格：' + 'ftp://172.17.192.170/pub/diff_list.xlsx')
