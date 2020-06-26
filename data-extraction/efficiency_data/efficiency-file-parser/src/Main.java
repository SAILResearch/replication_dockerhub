import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class Main {

	public static void main(String[] args) throws IOException {

		String basePath = "/home/msayagh/Documents/replication-18-ibrahim-dockerhub/Data-extraction/efficiency_data/container-efficiency-measure/src/container-efficiency-results";
		File file = new File(basePath);
		String[] directories = file.list();
		String output = "image, efficiency, wastedBytes, userWastedPercent\n";

		for (int i = 0; i < directories.length; i++) {
			
			String imageName = directories[i];
			
			String efficiencyFilePath = basePath + "/" + imageName + "/" + "efficiency.txt";
			
			File efficiencyFile = new File(efficiencyFilePath);

			FileInputStream efficiencyFileInputStream = new FileInputStream(efficiencyFile);

			byte[] efficiencyData = new byte[(int) file.length()];
			efficiencyFileInputStream.read(efficiencyData);
			efficiencyFileInputStream.close();
			String efficiencyDataString = new String(efficiencyData, "US-ASCII");
			
            
			output += imageName.replaceFirst("[.]", "/") + "," + getEfficiency(efficiencyDataString) + ","
					+ getWastedByte(efficiencyDataString) + "," + getUserWastedPercentage(efficiencyDataString) + "\n";

		}

		FileOutputStream efficiencyFileWriter = new FileOutputStream(new File("output.csv"));
		efficiencyFileWriter.write(output.getBytes());
		efficiencyFileWriter.close();
	}

	private static String getEfficiency(String efficiencyDataString) {
		return getStringFromPatternMatching(efficiencyDataString, "efficiency:\\s+\\d+(\\.\\d+)?");
	}

	private static String getWastedByte(String efficiencyDataString) {
		return getStringFromPatternMatching(efficiencyDataString, "wastedBytes:\\s+\\d+");
	}

	private static String getUserWastedPercentage(String efficiencyDataString) {
		return getStringFromPatternMatching(efficiencyDataString, "userWastedPercent:\\s+\\d+(\\.\\d+)?");
	}

	private static String getStringFromPatternMatching(String efficiencyDataString, String patternString) {
		Pattern pattern = Pattern.compile(patternString);
		Matcher matcher = pattern.matcher(efficiencyDataString);
		String matchedSequence = "";
		while (matcher.find()) {
			matchedSequence = matcher.group();
		}

		String[] splits = matchedSequence.split(":");

		return splits.length > 1 ? splits[1] : "";
	}
}
