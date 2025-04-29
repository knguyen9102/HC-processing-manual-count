 // Pulls up images for manual HC (optional: & syn) counts and saves result to table

// Duplicate all image files. Select and work with duplicates directory to perserve raw data
// Acknowledgements: imagej sc forum user David Mason
// https://forum.image.sc/t/saving-multipoint-counts-measurements/94554

//to count number of images in original folder and set folders directories
OrigDir=getDirectory("Select folder with deconvolved images to quantify.");
print("Working folder is: ", OrigDir);
MergedSaveDir=getDirectory("Select folder for saved merged images and results.");
print("Merged folder is: ", MergedSaveDir);
olist=getFileList(OrigDir);
m=lengthOf(olist);
print("The number of images to quantify is: "+m);

// Set the fish counter
CarryOn=1;

// --- Main Procedure ---
// open images
while (CarryOn > 0) {
	for(i = 0; i < m; i++){
		
	    open(OrigDir+olist[i]);
	    close("\\Others");
		Name = getTitle();
		CleanName = replace(Name, "\ -\ Deconvolved\ 20\ iterations,\ Type\ Blind.nd2", "");
		run("Duplicate...", "title=NM duplicate hyperstack");
		run("Split Channels");
		
		// Name channels
		selectWindow("C1-NM");
		DAPI = getTitle();
		selectWindow("C2-NM");
		MAGUK = getTitle();
		selectWindow("C3-NM");
		PARV = getTitle();
		selectWindow("C4-NM");
		CtBP = getTitle();
	
		// synapse count option and image pre processing
		// SynCount = getBoolean("Do you want to count synapses?", "Yes", "No");
		// if (SynCount <= 0){
			close( MAGUK );
			close( CtBP );
			selectWindow( DAPI );
			run("Subtract Background...", "rolling=100 stack");
			selectWindow( PARV );
			run("Subtract Background...", "rolling=100 stack");
			
			waitForUser("Adjust images.");
		/* } else {
			selectWindow( DAPI );
			run("Subtract Background...", "rolling=100 stack");
			selectWindow( MAGUK );
			run("Subtract Background...", "rolling=100 stack");
			selectWindow( PARV );
			run("Subtract Background...", "rolling=100 stack");
			selectWindow( CtBP );
			run("Subtract Background...", "rolling=100 stack");
			// need to write syn count code below
		} */
	
		// -- HC counts --
		// set temp variable, close unnecessary windows, and reset roi manager
		tmpHC=0;
		close( Name );
		// roiManager("reset");
		
		// merge channels and save 
		selectWindow("C1-NM");
		selectWindow("C3-NM");
		run("Merge Channels...", "c1=["+PARV+"]  c3=["+DAPI+"]  keep ignore");
		saveAs("tiff", MergedSaveDir + File.separator + CleanName + "_DAPI_PARV.tif");
		run("Z Project...", "projection=[Max Intensity]");
		saveAs("tiff", MergedSaveDir + File.separator + CleanName + "_DAPI_PARV_maxintensity.tif");
		PARV_DAPI = getTitle();
		
		// count
		setTool("multipoint");
		run("Tile");
		run("Synchronize Windows");
		waitForUser("Count HC for "+CleanName+" on max projection then hit OK to continue");
		selectWindow( PARV_DAPI );
		tmpHC=getValue("selection.size");
		setResult("Fish", i, CleanName);
		setResult("Pyknotic HC", i, tmpHC);
		
		// save points on image
		run("ROI Manager...");
		roiManager("add");
		roiName = call("ij.plugin.frame.RoiManager.getName", i); // gets the name of the last counted image points
	    roiManager("Select", i);
	    roiManager("rename", CleanName); // names the ROI with the image title
	    roiNewName = call("ij.plugin.frame.RoiManager.getName", i);
		print("ROI name changed from " + roiName + " to " + roiNewName);
		roiManager("Save", MergedSaveDir + File.separator + "NMRoiSet.zip");
		// close("ROI Manager");
		
		// update the display of the results table
		updateResults();
		saveAs("results", MergedSaveDir + File.separator + "_HC_counts.xls");
		
		// option to stop. Auto-stop when no more images
		CarryOn=getBoolean("Do you want to count more HC?", "Yes", "No");
			if (CarryOn == 0){
				i = m + 1;
				print("Finished with "+CleanName+" counted.");
			}
		}
		
	if (i == m){
		CarryOn = 0;
	}
}

// Done
waitForUser("Action Required." , "You're finished! Save the log please. End?");
close("ROI Manager");
run("Close All");