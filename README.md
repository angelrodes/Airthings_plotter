# Airthings plotter
A Matlab/Octave script that plots raw data provided by Airthings Wave air quality monitor.

Ángel Rodés, 2022 \
[www.angelrodes.com](https://www.angelrodes.com/)

## How to use

1. Follow the instructions from your Airthings Wave Plus monitor ans setup the app in your phone. Create a new account if you don't have one.
2. After a few hours, you can log in and see your data online at [dashboard.airthings.com](https://dashboard.airthings.com/)
3. Download your by clicking "Export to CSV":
![image](https://user-images.githubusercontent.com/53089531/191991436-8d520cce-e0a9-4901-9a91-c6e558ce6c81.png)
4. Run the script ```Plot_airthings_v1.m``` in MATLAB or octave to get your raw data plotted.

## Output

The script let you choose how many days to plot:

![image](https://user-images.githubusercontent.com/53089531/191992157-b0210de1-4d3d-471a-814c-ede03e683d81.png)

The output looks like this:

![image](https://user-images.githubusercontent.com/53089531/191994587-eac1e5b2-b108-4b6a-88e7-ed3a6049b0fd.png)

## Potential issues
Your csv should look like this:

![image](https://user-images.githubusercontent.com/53089531/191991075-5900ab53-ddfc-4321-a3cf-71188a065a8a.png)

If you have a different model you might get other data, or data separated by comma (,) instead of semicolon (;). If that is the case, you can change the first lines of the "load data" and "plot sttuff" sections in the script to make it work with you monitor.
