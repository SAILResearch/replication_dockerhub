import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileFilter;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

public class Main {

	public static String currentOfficialImage;
	public static String homePath = "/home/msayagh/Documents/replication-18-ibrahim-dockerhub/Data-extraction/efficiency_data/container-efficiency-measure/src/";
	public static String containerAnalysisBasePath = homePath;

	public static void main(String[] args) throws IOException, InterruptedException {

			runImageEfficiencyMeasure();
	}

	private static String getEfficiencyResult(String imageName) {
		try {		
			runProcess(String.format("docker pull %s", imageName));
			return runProcess(String.format("CI=true dive %s", imageName));
		} catch (InterruptedException e) {
			
			e.printStackTrace();
		}

		return "";
	}

	private static void runImageEfficiencyMeasure() {

		List<String> imageNames = getImageNames();
		
		String targetFolderPath = String.format("%s/container-efficiency-results/", containerAnalysisBasePath);

		int i = 1;

		for (String imageName : imageNames) {

			String folderDestination = targetFolderPath + imageName.replace('/', '.');
			File fileTobeCreated = new File(folderDestination);
			
			if(fileTobeCreated.exists() && (new File(folderDestination + "/efficiency.txt")).exists()) {
				continue;
			}
			if( ! fileTobeCreated.exists()) {
				fileTobeCreated.mkdirs();
			}
			
			releaseCache();
			
			DateTimeFormatter dtf = DateTimeFormatter.ofPattern("yyyy/MM/dd HH:mm:ss");
			LocalDateTime startsAt = LocalDateTime.now();

			System.out.println("Starts at: " + dtf.format(startsAt));

			System.out.println(i++ + " of " + imageNames.size());

			String efficiencyResult = "";
			
			try {
				efficiencyResult = getEfficiencyResult(imageName);
			} catch (Exception e) {
				// TODO: handle exception
			}
			
			writeToFile(folderDestination + "/" + "efficiency.txt", efficiencyResult);
		}
	}

	private static List<String> getImageNames() {
		String file = String.format(homePath  + "/unique_images.csv");

		List<String> imageNames = new ArrayList<String>();
		
		try (BufferedReader br = new BufferedReader(new FileReader(file))) {
			String line;
			//int i = 0;

			while ((line = br.readLine()) != null) {
				//if (i++ > 0)
					imageNames.add(line.trim());
			}
		} catch (Exception ex) {
			ex.printStackTrace();
		}

		Collections.shuffle(imageNames);
		//imageNames.add(0, currentOfficialImage);
		
		return imageNames.stream().distinct().collect(Collectors.toList());
	}

	private static String runProcess(String command) throws InterruptedException {

		Process process;
		BufferedReader br = null;
		System.out.println(command);
		try {
			process = new ProcessBuilder("/bin/bash", "-c", command).redirectErrorStream(true).start();
			
			InputStream is = process.getInputStream();
			InputStreamReader isr = new InputStreamReader(is);
			br = new BufferedReader(isr);
			String allText = "";
			String line;
			while ((line = br.readLine()) != null) {
				allText += line;
			}
			return allText;
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		return "";
	}

	private static void writeToFile(String filepath, String content) {

		BufferedWriter output = null;
		try {
			File file = new File(filepath);
			output = new BufferedWriter(new FileWriter(file));
			output.write(content);
		} catch (IOException e) {
			e.printStackTrace();
		} finally {
			if (output != null) {
				try {
					output.close();
				} catch (IOException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}
		}
	}
	
	private static void releaseCache() {
		File homeDirectory = new File(homePath);
		long freeSpace = homeDirectory.getFreeSpace() / 1024 / 1024 / 1024;
		System.out.println(freeSpace);
		while (freeSpace > 200) {
			try {				
				runProcess("docker rmi $(docker images -q | xargs shuf -n1 -e) -f");
				runProcess("docker rm $(docker ps -aq | xargs shuf -n1 -e) -f");
			} catch (Exception e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			freeSpace = homeDirectory.getFreeSpace() / 1024 / 1024 / 1024;
		}
	}
}
