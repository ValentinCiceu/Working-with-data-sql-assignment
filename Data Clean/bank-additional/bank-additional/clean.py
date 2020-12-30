
import csv

with open("bank-additional-full.csv", 'rb') as input, open('bank-additional-full-clean.csv', 'wb') as output:
    reader = csv.reader(input, delimiter = ';')
    writer = csv.writer(output, delimiter = ';')

    all = []
    row = next(reader)
    row.insert(0, 'ID')
    all.append(row)
    count = 0
    for row in reader:
        count += 1
        row.insert(0, count)
        all.append(row)
    writer.writerows(all)