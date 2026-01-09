import pathlib
import re
import sys

lcov_path = pathlib.Path('coverage/lcov.info')
if not lcov_path.exists():
    sys.exit('coverage/lcov.info not found. Run `flutter test --coverage` first.')

total_lines = 0
covered_lines = 0
file_stats = []

for chunk in lcov_path.read_text().split('end_of_record'):
    if not chunk.strip():
        continue
    file_match = re.search(r'SF:(.+)', chunk)
    lf_match = re.search(r'LF:(\d+)', chunk)
    lh_match = re.search(r'LH:(\d+)', chunk)
    if lf_match and lh_match:
        lf_value = int(lf_match.group(1))
        lh_value = int(lh_match.group(1))
        total_lines += lf_value
        covered_lines += lh_value
        if file_match:
            filename = file_match.group(1).strip()
            pct = (lh_value / lf_value * 100) if lf_value else 0.0
            file_stats.append((filename, lf_value, lh_value, pct))

if total_lines == 0:
    sys.exit('No coverage data found in lcov file.')

coverage = covered_lines / total_lines * 100
print(f'Total lines: {total_lines}')
print(f'Covered lines: {covered_lines}')
print(f'Coverage: {coverage:.2f}%')

file_stats.sort(key=lambda item: item[3])
print('\nLowest coverage files:')
for name, lf_value, lh_value, pct in file_stats[:15]:
    print(f'  {name} -> {pct:.1f}% ({lh_value}/{lf_value})')
