import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import fileUtilities.ReadingUtilities;

public class mostduplicated {

	public static void main(String[] args) throws IOException {

		String basePath = "C:\\Users\\sayag\\OneDrive - Queen's University\\research\\replication-18-ibrahim-dockerhub\\Data-extraction\\efficiency_data\\container-efficiency-measure\\src\\container-efficiency-results";
		File file = new File(basePath);
		String[] directories = file.list();
		String output = "image,count,size,file\n";

		for (int i = 0; i < directories.length; i++) {

			String imageName = directories[i];
			String efficiencyFilePath = basePath + "/" + imageName + "/" + "efficiency.txt";

			List<String> efficiencyDataString = ReadingUtilities.getLines(efficiencyFilePath);
			System.out.println(i + " out of " + directories.length);
			if(efficiencyDataString.size() > 0) {
				output += getDuplicatedFiles(imageName.replaceFirst("[.]", "/"), efficiencyDataString.get(0)).replace(";", "\n");
			}
		}

		FileOutputStream efficiencyFileWriter = new FileOutputStream(new File("duplicatedResources.csv"));
		efficiencyFileWriter.write(output.getBytes());
		efficiencyFileWriter.close();
	}

	private static String getDuplicatedFiles(String image, String efficiencyDataString) {
		if (! efficiencyDataString.contains("Inefficient Files")) {
			return "";
		}
		System.out.println(image);
		if (image.equals("mailu/nginx")) {
			System.out.println("break");
		}
		String inefficientfiles= efficiencyDataString.substring(efficiencyDataString.indexOf("Inefficient Files"));
		inefficientfiles = inefficientfiles.substring(inefficientfiles.indexOf("File Path") + "File Path".length());
		inefficientfiles = inefficientfiles.substring(0, inefficientfiles.indexOf("["));
		while(inefficientfiles.contains("  ")) {
			inefficientfiles = inefficientfiles.replaceAll("  ", " ");
		}
		if (inefficientfiles.startsWith("None")) {
			return "";
		}
		while(inefficientfiles.startsWith(" ")) {
			inefficientfiles = inefficientfiles.substring(1);
		}
		int i = 0;
		String[] s = inefficientfiles.split(" ");
		String result = "";
		for ( int j = 0 ; j < s.length; j++) {
//			if (s[j].equals("/usr/lib/python3.6/site-packages/setuptools/command/launcher")) {
//				System.out.println("break");
//			}
			if (i == 1) {
				result += s[j];
			} else {
				if (i == 3) {
					if (j == s.length - 1) {
						result += s[j] + ";";
					} else {
						result += s[j] + ";" + image + ",";
					}
				} else {
					if ( i ==0 && ! isNumeric (s[j])) {
						result = result.substring(0, result.lastIndexOf(";"));
						result += s[j] + ";" + image + ",";
						i --;
					} else {
						result += s[j] + ",";
					}
				}
			}
			if (i == 3) {
				i = 0;
			} else {
				i++;
			}
		}

		inefficientfiles = image + "," + result;
		return inefficientfiles; 

	}

	public static boolean isNumeric(String strNum) {
		if (strNum == null) {
			return false;
		}
		try {
			double d = Double.parseDouble(strNum);
		} catch (NumberFormatException nfe) {
			return false;
		}
		return true;
	}

}
