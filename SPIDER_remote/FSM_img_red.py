'''
This script allows to display an image according to a register value.
You need to get the correct index by using dump_reg_red.py script with DUMP_ALL = True
after setting down the link!
COnfigure the found index in REG_INDEX variable.

Based on Tkinter image slideshow (vegaseat daniweb.com)
https://www.daniweb.com/programming/software-development/code/468841/tkinter-image-slide-show-python
'''

SWITCH_ID = 1
REG_NAME = 'reg_state_red'
JSON = 'SPIDER_remote.json'

REG_INDEX = 2000 # Configure!!!

import subprocess

try:
        import Tkinter as tk
except ImportError:
        subprocess.call("sudo apt-get -q -y install python-tk".split())
        print ('Tkinter has been installed. Please relaunch this script!')
        exit()

class App(tk.Tk):
    '''Tk window/label adjusts to size of image'''
    def __init__(self, image_files, x, y, delay):
        # the root will be self
        tk.Tk.__init__(self)
        # set x, y position only
        self.geometry('+{}+{}'.format(x, y))
        self.delay = delay
        self.picture_display = tk.Label(self)
        self.picture_display.pack()
        self.pyimage_list = [(tk.PhotoImage(file=image), image) for image in image_files]

    def show_slides(self):
        cmd = 'echo "register_read '+REG_NAME+' '+str(REG_INDEX)+'" | ~/bmv2/targets/simple_switch/sswitch_CLI '+JSON+' '+str(22222+SWITCH_ID-1)+' | grep '+REG_NAME

        ps = subprocess.Popen(cmd,shell=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
        output = ps.communicate()[0]
	idx = 0
	if len(output)!=0:
        	idx_str = output.split()[-1]
		if idx_str in [str(x) for x in range(5)]:
			idx = int(idx_str)
	img_object, img_name = self.pyimage_list[int(idx)]
	self.picture_display.config(image=img_object)
	#self.title(img_name)
        self.after(self.delay, self.show_slides)
    def run(self):
        self.mainloop()
# set milliseconds time between slides
delay = 200
image_files = [
'img/r0.png',
'img/r1.png',
'img/r2.png',
'img/r3.png',
'img/r4.png'
]
# upper left corner coordinates of app window
x = 100
y = 50
app = App(image_files, x, y, delay)
app.show_slides()
app.run()
