import os
import sys
import re

if __name__ == "__main__":
	diff_file_name = "xx"
	diff_patch_name = "yy"
	diff_pattern = "diff --git "
	right_diff_pattern = "@@ -1,4 +1,4 @@\n"
	os.system("git diff > " + diff_file_name + "\n")
	diff_file = open(diff_file_name, 'r')
	diff_patch = open(diff_patch_name, 'w')
	lines = diff_file.readlines()
	i = 0
	pattern = re.compile(r'[-+]From \w{40} \w+ \w+ \d+ \d+:\d+:\d+ \d+')
	for line in lines:
		right_diff = ""
		if line.find(diff_pattern) >= 0:
			if lines[i+4] == right_diff_pattern:
				match1 = pattern.match(lines[i+5])
				match2 = pattern.match(lines[i+6])
				if match1 and match2:
					for j in range(0,10):
						right_diff = right_diff + lines[i+j]
					diff_patch.write(right_diff)
		i = i + 1
	diff_file.close()
	diff_patch.close()
	os.system("patch -p1 -R < " + diff_patch_name + "\n")
	os.system("rm " + diff_file_name + " " + diff_patch_name + "\n")
