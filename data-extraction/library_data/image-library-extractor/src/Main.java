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
	public static String homePath = "/home/msayagh/Documents/replication-18-ibrahim-dockerhub/Data-extraction/library_data/image-library-extractor/src"; //put you home path here
	public static String containerAnalysisBasePath = homePath+"/analysis-results";

	public static void main(String[] args) throws IOException, InterruptedException {

			currentOfficialImage = args[0];
			runProcess(String.format("mkdir -p %s/container-analysis-result-%s", containerAnalysisBasePath, currentOfficialImage));
			runContainerAnalyzer();
	}

	private static void runContainerAnalyzer() {

		List<String> imageNames = getImageNames();
		
		String targetFolderPath = String.format("%s/container-analysis-result-%s/", containerAnalysisBasePath, currentOfficialImage);

		int i = 1;

		for (String imageName : imageNames) {

			releaseCache();
			
			DateTimeFormatter dtf = DateTimeFormatter.ofPattern("yyyy/MM/dd HH:mm:ss");
			LocalDateTime startsAt = LocalDateTime.now();

			System.out.println("Starts at: " + dtf.format(startsAt));

			System.out.println(i++ + " of " + imageNames.size());
			

			String folderDestination = targetFolderPath + imageName.replace('/', '.');
			if ((new File(folderDestination)).isDirectory() && (new File(folderDestination + "/" + "apk_apt.txt")).exists()) {
				System.out.println(imageName + " exists");
				continue;
			}
			new File(folderDestination).mkdirs();

			String apk_apt = getAptAndApkLibraires(imageName);
			writeToFile(folderDestination + "/" + "apk_apt.txt", apk_apt);
		}
	}
	
	private static String getAptAndApkLibraires(String imageName) {
		try {
			runProcess(String.format("docker pull %s", imageName));
			return runProcess(String.format("snyk-docker-analyzer analyze %s", imageName));
		} catch (InterruptedException e) {
			
			e.printStackTrace();
		}

		return "";
	}


	private static List<String> getImageNames() {
		String file = String.format("%s/sampled-images/%s_images.csv", homePath, currentOfficialImage);

		List<String> imageNames = new ArrayList<String>();
		
		try (BufferedReader br = new BufferedReader(new FileReader(file))) {
			String line;
			int i = 0;

			while ((line = br.readLine()) != null) {
				if (i++ > 0)
					imageNames.add(line.split(",")[1]);

			}
		} catch (Exception ex) {
			ex.printStackTrace();
		}

		Collections.shuffle(imageNames);
		imageNames.add(0, currentOfficialImage);
		
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
	
	private static void deleteDirectoryStream(Path path) throws IOException {
		Files.walk(path).sorted(Comparator.reverseOrder()).map(Path::toFile).forEach(File::delete);
	}

	private static void releaseCache() {
		
		File cacheDirectory = new File(homePath);
		long freeSpace = cacheDirectory.getFreeSpace() / 1024 / 1024 / 1024; //free space in GB

		while (freeSpace < 10) {
			try {
				runProcess("docker rmi $(docker images -q | xargs shuf -n1 -e) -f");

			} catch (Exception e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			freeSpace = cacheDirectory.getFreeSpace() / 1024 / 1024 / 1024;
		}
	}
}
