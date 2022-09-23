# Airthings plotter
A Matlab/Octave script that plots raw data provided by Airthings Wave air quality monitor.

Ángel Rodés, 2022 \
[www.angelrodes.com](https://www.angelrodes.com/)

## How to use

1. Follow the instructions from your Airthings Wave Plus monitor to setup the app in your phone. Create a new account if you don't have one.
2. After a few hours, you can log in and see your data online at [dashboard.airthings.com](https://dashboard.airthings.com/)
3. Download your by clicking "Export to CSV":
![image](https://user-images.githubusercontent.com/53089531/191995763-0887d323-0b59-41bb-aa67-84ccd3095d4e.png)
4. Run the script ```Plot_airthings_v1.m``` in MATLAB or Octave to get your raw data plotted.

## Output

The script will ask you where is the CSV file:

![image](https://user-images.githubusercontent.com/53089531/191996233-8f77abce-fcce-444a-b8ef-7f97279a4713.png)

It also lets you choose how many days to plot:

![image](https://user-images.githubusercontent.com/53089531/191992157-b0210de1-4d3d-471a-814c-ede03e683d81.png)

The output looks like this:

![image](https://user-images.githubusercontent.com/53089531/191994587-eac1e5b2-b108-4b6a-88e7-ed3a6049b0fd.png)

## Potential issues
Your csv should look like this:

![image](https://user-images.githubusercontent.com/53089531/191991075-5900ab53-ddfc-4321-a3cf-71188a065a8a.png)

If you have a different model you might get other data, or data separated by comma (,) instead of semicolon (;). If that is the case, you can change the first lines of the "load data" and "plot sttuff" sections in the script to make it work with you monitor.
