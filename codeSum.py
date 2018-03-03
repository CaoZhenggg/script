#!/usr/bin/env python
# _*_ coding: utf-8 _*_
# Author: CaoZheng


from __future__ import print_function
import sys
reload(sys)
sys.setdefaultencoding('utf8')
import os
import xlsxwriter


param_list = sys.argv

sum_file_list = param_list[1:]

if os.path.exists('/var/ftp/pub/codeSum.xlsx'):
    os.remove('/var/ftp/pub/codeSum.xlsx')

workbook = xlsxwriter.Workbook('/var/ftp/pub/codeSum.xlsx')
#format_string = workbook.add_format({})
format_number = workbook.add_format({'right': True})

for sum_file in sum_file_list: 
    with open(sum_file, 'r') as f:
        sum_list = list(line.split() for line in f.readlines())
        
        sum_file_name = os.path.basename(sum_file)
        worksheet01 = workbook.add_worksheet(sum_file_name)
        worksheet01.set_column('A:B', 10) 

        row = 0
        col = 0

        for name, num in (sum_list):
            int_num = int(num)
            worksheet01.write(row, col, name)
            worksheet01.write(row, col + 1, int_num, format_number)
            row += 1

worksheet = workbook.add_worksheet('总计')
row = 0
col = 0

for sum_file in sum_file_list: 
    with open(sum_file, 'r') as f:
        sum_list = list(line.split() for line in f.readlines())
        
        worksheet.set_column('A:B', 10) 


        for name, num in (sum_list):
            int_num = int(num)
            worksheet.write(row, col, name)
            worksheet.write(row, col + 1, int_num, format_number)
            row += 1

workbook.close()


print('表格：' + 'ftp://172.17.192.170/pub/codeSum.xlsx')
