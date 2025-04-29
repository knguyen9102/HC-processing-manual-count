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
		run("Subtract Background...", "rolling=75 stack");
		selectWindow("C2-NM");
		EdU = getTitle();
		run("Subtract Background...", "rolling=75 stack");
		selectWindow("C3-NM");
		PARV = getTitle();
		run("Subtract Background...", "rolling=75 stack");
		waitForUser("Adjust brightness then hit OK to continue");
		
	/*
		// synapse count option and image pre processing
		// SynCount = getBoolean("Do you want to count synapses?", "Yes", "No");
		// if (SynCount <= 0){
			close( MAGUK );
			close( CtBP );
			selectWindow( DAPI );
			run("Subtract Background...", "rolling=100 stack");
			selectWindow( PARV );
			run("Subtract Background...", "rolling=100 stack");
		 } else {
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
		tmpEdU=0;
		close( Name );
		// roiManager("reset");
		
		// merge DAPI and EdU and save 
		selectWindow("C1-NM");
		selectWindow("C2-NM");
		run("Merge Channels...", "c2=["+PARV+"]  c3=["+DAPI+"]  keep ignore");
		saveAs("tiff", MergedSaveDir + File.separator + CleanName + "_DAPI_Parv.tif");
		PARV_DAPI = getTitle();
		run("Z Project...", "projection=[Max Intensity]");
		saveAs("tiff", MergedSaveDir + File.separator + CleanName + "_DAPI_Parv_maxintensity.tif");
		PARV_DAPI_m = getTitle();
		
		// merge PARV and EdU and save 
		selectWindow("C2-NM");
		selectWindow("C3-NM");
		run("Merge Channels...", "c1=["+EdU+"]  c2=["+PARV+"]  keep ignore");
		saveAs("tiff", MergedSaveDir + File.separator + CleanName + "_PARV_EdU.tif");
		PARV_EdU = getTitle();
		run("Z Project...", "projection=[Max Intensity]");
		saveAs("tiff", MergedSaveDir + File.separator + CleanName + "_PARV_EdU_maxintensity.tif");
		PARV_EdU_m = getTitle();
		
		// count
		setTool("multipoint");
		run("Tile");
		run("Synchronize Windows");
		waitForUser("Count HC for "+CleanName+" then hit OK to continue");
		tmpHC=getValue("selection.size");
		setResult("Fish", i, CleanName);
		setResult("HC", i, tmpHC);
		
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
		
		// clear HC counts
		
		/*selectWindow("C1-NM");
		run("Select None");
		selectWindow("C2-NM");
		run("Select None");
		selectWindow("C3-NM");
		run("Select None");*/
		
		selectWindow( PARV_EdU );
		run("Select None");
		selectWindow( PARV_DAPI );
		run("Select None");
		
		
		waitForUser("Count EdU/HC overlaps for "+CleanName+" on PARV/EdU merge then hit OK to continue");
		tmpEdU=getValue("selection.size");
		setResult("EdU", i, tmpEdU);
		
		// update the display of the results table
		updateResults();
		saveAs("results", MergedSaveDir + File.separator + "_HC_counts.xls");
		
		// option to stop and forced stop when no more images
		CarryOn=getBoolean("Do you want to count more HC?", "Yes", "No");
			if (CarryOn == 0){
				i = m + 1;
				print("Ended with "+CleanName+" counted.");
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