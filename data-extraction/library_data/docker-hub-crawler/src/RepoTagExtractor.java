import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedList;
import java.util.List;
import org.json.JSONArray;
import org.json.JSONObject;
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import org.openqa.selenium.firefox.FirefoxDriver;

import fileUtilities.WritingUtilities;

public class RepoTagExtractor {

	public static void SaveDataToFile(List<ImageTag> tags) {
		List<String> data = new LinkedList<>();
		for (int i = 0; i < tags.size(); i++) {
			ImageTag tag = tags.get(i);
			data.add(tag.officialImageName + "," + tag.imageName + "," + tag.tagName + "," + tag.size + ","
					+ tag.lastUpdateDate);
		}
		WritingUtilities.writeLines("image_tags_with_update_date.csv", data);
	}

	private static List<Image> getImages() throws IOException {
		List<Image> images = new ArrayList<Image>();

		String imagesCsv = new String(Files.readAllBytes(Paths.get("uniqueOriginalList.csv")), StandardCharsets.UTF_8);
		List<String> lines = Arrays.asList(imagesCsv.split("\n"));
		for (String line : lines) {
			String[] splits = line.split(",");
			images.add(new Image(splits[0].trim(), splits[1].trim()));
		}
		return images;
	}
	
	public static void main(String[] args) throws  IOException {

		/*System.setProperty("webdriver.chrome.driver", "chromedriver.exe");
		ChromeOptions chromeOptions = new ChromeOptions();
		chromeOptions.addArguments("--headless");
		chromeOptions.addArguments("--no-sandbox");
		
		WebDriver driver = new ChromeDriver(chromeOptions);
		WebDriver restApiDriver = new ChromeDriver(chromeOptions);
	*/
		System.setProperty("webdriver.firefox.bin","C:\\Program Files\\Mozilla Firefox\\Firefox.exe");
		System.setProperty("webdriver.gecko.driver", "geckodriver.exe");
		WebDriver driver = new FirefoxDriver();
		// WebDriver restApiDriver = new FirefoxDriver();
		
		List<String> data = new LinkedList<>();
		data.add("official_image_name, mage_name, tag_name, size, last_updated");
		WritingUtilities.writeLines("image_tags_with_update_date.csv", data);

		List<Image> images = getImages();
		List<ImageTag> tags = new LinkedList<ImageTag>();

		for (int j = 2210; j < images.size(); j++) {

			System.out.println(j);

			String currentOfficialImageName = images.get(j).officiaImage;
			String currentImageName = images.get(j).image;

			if (!currentImageName.contains("/")) {
				currentImageName = "library/" + currentImageName;
			}

			String urlPattern = "https://registry.hub.docker.com/v2/repositories/%s/tags";
			String url = String.format(urlPattern, currentImageName);

			String nextUrl = url;

			while (!nextUrl.isEmpty()) {

				driver.get(nextUrl);
				String allTags = driver.findElement(By.tagName("html")).getText();

				JSONObject allTagsJsonObject = new JSONObject();
				JSONArray tagElements = new JSONArray();

				try {
					allTagsJsonObject = new JSONObject(allTags);

					tagElements = allTagsJsonObject.getJSONArray("results");

				} catch (Exception e) {
					// TODO: handle exception
				}

				for (int i = 0; i < tagElements.length(); i++) {
					JSONObject tagElement = tagElements.getJSONObject(i);

					String currentTagName = "";
					try {
						currentTagName = tagElement.getString("name");
					} catch (Exception e) {
						System.out.println("Exception in name!");
					}

					int size = 0;
					try {
						size = tagElement.getInt("full_size");
					} catch (Exception e) {
						System.out.println("Exception in size!");
					}

					String lastUpdateDate = "";

					try {
						lastUpdateDate = tagElement.getString("last_updated");
					} catch (Exception e) {
						System.out.println("Exception in date!");
					}

					tags.add(new ImageTag(currentOfficialImageName, currentImageName, currentTagName, lastUpdateDate,
							Integer.toString(size)));
				}
				try {
					nextUrl = allTagsJsonObject.getString("next");
				} catch (Exception e) {
					nextUrl = "";
				}
			}

			SaveDataToFile(tags);
			tags = new LinkedList<ImageTag>();

		}

		//restApiDriver.quit();
		driver.quit();

		SaveDataToFile(tags);
	}
}