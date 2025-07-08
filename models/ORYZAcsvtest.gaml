/**
* Name: ORYZAcsvtest
* Based on the internal empty template. 
* Author: pc
* Tags: 
*/


model ORYZAcsvtest

/* Insert your model definition here */

global {
	string op_file <- "../includes/Results/2016/op2016.csv";
	string res_file <- "C:\\Users\\pc\\Downloads\\res2016.csv";
	
	init {
		write "Testing CSV file: " + res_file;
		
		if (file_exists(res_file)) {
			write "File exists!";
			
			matrix data <- matrix(csv_file(res_file).contents);
			
			if (data != nil) {
				write "SUCCESS: File read as matrix";
				write "Rows: " + data.rows;	
				write "Columns: " + data.columns;
				
				if (data.rows > 0 and data.columns > 0) {
					write "First cell: " + data[0,0];
				}		
			} else {
				write "ERROR: Could not read file as matrix";
			}
		} else {
			write "ERROR: File does not exist!";
		}
	}
}

experiment "Test" type:gui {
	output {
		display "Test" {
			graphics "results" {
				draw "Check console" at: {100,100} color:#black;
			}
		}
	}
}