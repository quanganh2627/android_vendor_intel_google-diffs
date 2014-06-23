import os
import sys
import re

old_path = "vendor/intel/google_diffs/"

def check_project(PList, name):
	for proj in PList:
		if proj !="" and proj !="vendor/intel/google_diffs" and name.find(proj) >= 0 and name.find("buildbot_acs") < 0:
			print name + " in "+ proj
			return True
	return False

def get_changeID(folder):
	tmpfile = "x"
	os.system("find " + folder + " -name \"*.patch\" > " + tmpfile + "\n")
	tmpf = open(tmpfile, 'r') 
	lines = tmpf.readlines()
	tmpf.close()
	os.system("rm "  + tmpfile + "\n")
	changeIDp = "Change-Id:"
	IDLIST = {}
	for line in lines:
		patch = line.split('\n')[0]
		if os.path.isfile(patch):
			pfile = open(patch, 'r')
			for pline in pfile.readlines():
				if pline.find(changeIDp) == 0:
					pline = pline.split(' ')[1]
					pline = pline.split('\n')[0]
					#print "patch name:" + line + " changeid:" + pline
					IDLIST[pline] = patch
			pfile.close()
	return IDLIST
	#print plist

line_pattern = ["+From", "+index", "+@@"]

# for the line we need ignore include "+From:" or "+index" in the head of line
def bad_line(line):
	for pattern in line_pattern:
		if line.find(pattern) == 0:
			return True
	return False

# for the diff we need take care
def good_diff(diff):
	#print diff
	good = True
	diff_list = diff.split('\n')
	plus_list = []
	minus_list = []
	for line in diff_list:
		if line.find('+') == 0:
			plus_list.append(line)
		if line.find('-') == 0:
			minus_list.append(line)

	n_plus = len(plus_list)
	n_minus = len(minus_list)
	if n_plus != n_minus:
		return True
	for pline in plus_list:
		if not bad_line(pline):
			return True
	return False

def modified(old, new):
	tmpfile = "x"
	os.system("diff -Nur " + old + " " + new + " > " + tmpfile + "\n")
	tmpf = open(tmpfile, 'r') 
	lines = tmpf.readlines()
	tmpf.close()
	os.system("rm "  + tmpfile + "\n")
	diff = False
	right_diff = ""
	for line in lines: 
		if right_diff != "":
			right_diff = right_diff + line
		if line.find("@@") == 0:
			if right_diff != "":
				diff = good_diff(right_diff)
				if diff:
					right_diff = ""
					break
			lineL = line.split(' ')
			# for "@@ -x1,y1 +x2,y2 @@", we need "x1,y1" == "x2,y2"
			if lineL[1][1:] != lineL[2][1:]:
				#os.system("diff -Nur " + old + " " + new + "\n")
				diff = True
				right_diff = ""
				break
			else:
				right_diff = line

	if right_diff != "":
		diff = good_diff(right_diff)
	if diff:
		print "cp " + new + " to " + old
		os.system("cp " + new + " " + old + "\n")
		newname = os.path.split(new)[1]
		oldname = os.path.split(old)[1]
		oldpath = os.path.split(old)[0]
		newnum = newname.split("-")[0]
		oldnum = oldname.split("-")[0]
		if newnum != oldnum:
			renewname = oldnum + "-" + newname[newname.find("-") + 1:]
			cmd = "mv " + old + " " + oldpath + "/" + renewname + "\n"
			print cmd
			os.system(cmd);


def _Main(argv):
	new = argv[0]
	old = old_path + argv[1] + "/patches/"
        print "generate the patches into " + old
	plistf_n = ".repo/project.list"
	plistf = open(plistf_n, 'r')
	PList = plistf.read().split('\n')
	plistf.close()
	if os.path.isdir(old) and os.path.isdir(new):
		oldIDList = get_changeID(old)
		newIDList = get_changeID(new)
		for key in newIDList.keys():
			if oldIDList.has_key(key):
				modified(oldIDList[key], newIDList[key])
				del oldIDList[key]
			else:
				old_file= old + newIDList[key].split(new)[1]
				new_file= new + newIDList[key].split(new)[1]
				oldpath = os.path.split(old_file)[0]
				print "add " + new_file + " to " + old_file
				if not os.path.isdir(oldpath):
					os.system("mkdir -p " + oldpath + "\n")
				os.system("cp " + new_file + " " + old_file + "\n")
			del newIDList[key]
		for key in oldIDList.keys():
			if check_project(PList, oldIDList[key]):
				newpath =  old + oldIDList[key].split(new)[1]
				print "del " + oldIDList[key]
				os.system("rm -f " + oldIDList[key] + "\n")
			del oldIDList[key]
		del oldIDList
		del newIDList
		
	else:
		print "Error: Not a folder!"
	del PList
	

if __name__ == "__main__":

	if len(sys.argv) == 3:
		_Main(sys.argv[1:])
	else:
		print "Error Usage!"
