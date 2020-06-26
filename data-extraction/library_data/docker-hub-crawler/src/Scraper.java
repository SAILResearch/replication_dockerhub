
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.openqa.selenium.By;
import org.openqa.selenium.NoSuchElementException;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import org.openqa.selenium.firefox.FirefoxDriver;

import fileUtilities.WritingUtilities;

public class Scraper {
	private static final Logger logger = Logger.getLogger(Scraper.class.getName());

	public static class RateLimitException extends Exception {
		private static final long serialVersionUID = 1L;

		public RateLimitException(String msg) {
			super(msg);
		}
	}

	private static WebDriver githubDriver;
	private static long delay = 2000;

	public static void SaveDataToFile(List<DockerProperties> dockers) {
		List<String> data = new LinkedList<>();
		for (int i = 0; i < dockers.size(); i++) {
			data.add(dockers.get(i).parentDockerImageName + "," + dockers.get(i).name + "," + dockers.get(i).isOffcial
					+ "," + dockers.get(i).link + "," + dockers.get(i).numberOfPulls + ","
					+ dockers.get(i).numberOfStars + "," + dockers.get(i).gitUrl);
		}
		WritingUtilities.writeLines("all_crawled_images.csv", data);
	}

	public static String GetGitHubRepoRootUrl(List<WebElement> githubRepoUrls) {

		for (int i = 0; i < githubRepoUrls.size(); i++) {
			String[] tokens = githubRepoUrls.get(i).getAttribute("href").split("/");
			String gitHubRepoBaseUrl = "";
			if (tokens.length > 4) {
				gitHubRepoBaseUrl = "https://github.com/" + tokens[3] + "/" + tokens[4] + ".git";
				return gitHubRepoBaseUrl;
			}
		}
		return "";
	}

	public static String getGithubURL(String url) {
		String gitUrl = "";
		List<WebElement> linksToGitHub;
		String probableGitHubLink = null;
		try {
			githubDriver.get(url);
			Thread.sleep(delay);
			try {
				linksToGitHub = githubDriver.findElements(By.cssSelector("a[href*='github.com']"));
			} catch (NoSuchElementException e) {
				linksToGitHub = null;
				logger.log(Level.SEVERE, e.toString(), e);
				System.out.println(e.toString());
			}

			if (linksToGitHub != null && linksToGitHub.size() > 0) {
				probableGitHubLink = GetGitHubRepoRootUrl(linksToGitHub);
			}
			List<WebElement> github = githubDriver.findElements(By.className("Card__block___1G9Iy"));
			if (github.size() == 5) {
				gitUrl = "https://github.com/" + github.get(4).getText().replaceAll(" ", "") + ".git";
			}
		} catch (Exception e) {
			logger.log(Level.SEVERE, e.toString(), e);
			System.out.println(e.toString());
		}
		if (gitUrl != null && gitUrl != "") {
			return gitUrl;
		}
		return probableGitHubLink;
	}

	private static List<DockerProperties> getDockerImages(WebDriver driver, String url, String parentDockerImageName)
			throws RateLimitException {

		List<DockerProperties> dockers = new LinkedList<DockerProperties>();

		try {
			driver.get(url);
			
			Thread.sleep(delay);

			List<WebElement> h1s = driver.findElements(By.className(
					//"RepositoryListItem__repositoryListItem___w1rvf"
					"styles__searchResult___EBKah"));
			Iterator<WebElement> iter = h1s.iterator();

			while (iter.hasNext()) {
				try {
					System.out.println("iter");
					WebElement current = iter.next();
					WebElement name = current.findElement(By.className(
							//"RepositoryListItem__repoName___28cOR"
							"styles__name___2198b"
							));
					WebElement link = current;/*.findElement(By.className(
							//"RepositoryListItem__flexible___3R0Sg"
							"styles__searchResult___EBKah"
							));*/
					List<WebElement> isOfficialElements = current.findElements(By.className(
							"styles__officialImageBanner___1Ey-B"
							//"undefined"
							));
					List<WebElement> popularity = current
							.findElements(By.className(
									//"RepositoryListItem__value___1Wqzm"
									"styles__stats___3fhCd"));

					String gitUrl = "";//getGithubURL(link.getAttribute("href"));

					int starsCount = 0;
					String stars = "";
					if (popularity.size() > 0 && popularity.get(0).getText().contains("Star")) {
						stars = popularity.get(0).getText();
					} else {
						if (popularity.size() > 1 && 
								popularity.get(1).getText().contains("Star")) {
							stars = popularity.get(1).getText();
						}
					}
					stars = stars.replace("+", "");
					stars = stars.replace("Stars", "");
					stars = stars.replace("Star", "");
					stars = stars.replaceAll("\n", "");

					if (stars.contains("M")) {
						stars = stars.replaceAll("M", "");
						starsCount = (int) (Double.parseDouble(stars) * 1000000);	
					} else {
						if (stars.contains("K")) {
							stars = stars.replaceAll("K", "");
							starsCount = (int) (Double.parseDouble(stars) * 1000);
						} else {
							if (! stars.isEmpty()) {
								starsCount = Integer.parseInt(stars);
							} else {
								starsCount = -1;
							}
						}
					}

					// Downloads
					int downloadsCount = 0;
					String downloads = "";
					if (popularity.size() > 0 && popularity.get(0).getText().contains("Download")) {
						downloads = popularity.get(0).getText();
					} else {
						if (popularity.size() > 1 && 
								popularity.get(1).getText().contains("Download")) {
							downloads = popularity.get(1).getText();
						}
					}
					downloads = downloads.replace("+", "");
					downloads = downloads.replace("Downloads", "");
					downloads = downloads.replace("Download", "");
					downloads = downloads.replaceAll("\n", "");

					if (downloads.contains("M")) {
						downloads = downloads.replaceAll("M", "");
						downloadsCount = (int) (Double.parseDouble(downloads) * 1000000);	
					} else {
						if (downloads.contains("K")) {
							downloads = downloads.replaceAll("K", "");
							downloadsCount = (int) (Double.parseDouble(downloads) * 1000);
						} else {
							if (! downloads.isEmpty()) {
								downloadsCount = Integer.parseInt(downloads);
							} else {
								downloadsCount = -1;
							}
						}
					}


					// if (starsCount > 2) {
					dockers.add(new DockerProperties(parentDockerImageName, link.getAttribute("href"), name.getText(),
							starsCount, downloadsCount, gitUrl, isOfficialElements.size() == 1 ? 1 : 0));
					//if (dockers.size() == 10) {
					//	Collections.sort(dockers);
					//	SaveDataToFile(dockers);
					//	dockers = new ArrayList<>();
					//}
					// }
				} catch (Exception e) {
					logger.log(Level.SEVERE, e.toString(), e);
					System.out.println(e.toString());
				}
			}
		} catch (Exception e) {
			logger.log(Level.SEVERE, e.toString(), e);
			System.out.println(e.toString());
		}

		return dockers;
	}

	private static List<String> getListOfBaseDockerImage() throws InterruptedException {
		List<String> parent_images = Arrays.asList(
				"nginx", 
				"cassandra", 
				"java", 
				"mongo", //"httpd", 
				"mysql"
				);
		return parent_images;
	}

	public static void main(String[] args) throws RateLimitException, InterruptedException {
		System.setProperty("webdriver.firefox.bin","C:\\Program Files\\Mozilla Firefox\\Firefox.exe");
		System.setProperty("webdriver.gecko.driver", "geckodriver.exe");
		WebDriver driver = new FirefoxDriver();
		githubDriver = new FirefoxDriver();

		/*
		System.setProperty("webdriver.chrome.driver", "chromedriver");
		ChromeOptions chromeOptions = new ChromeOptions();
		chromeOptions.addArguments("--headless");
		chromeOptions.addArguments("--no-sandbox");

		WebDriver driver = new ChromeDriver(chromeOptions);
		githubDriver = new ChromeDriver(chromeOptions);
		 */
		List<String> data = new LinkedList<>();
		data.add("ParentDockerImageName, Name, Offcial, DockerhubLink, NumberOfPulls, NumberOfStars, GithubCloneLink");
		WritingUtilities.writeLines("data.csv", data);

		List<String> parentDockerHubImages = getListOfBaseDockerImage();

		for (int j = 0; j < parentDockerHubImages.size(); j++) {

			List<DockerProperties> dockers = new LinkedList<DockerProperties>();
			Thread.sleep(delay);

			String url = String.format(
					//"https://hub.docker.com/search/?isAutomated=0&isOfficial=0&pullCount=0&q=%s&starCount=0&page="
					"https://hub.docker.com/search?type=image&q=%s&page=",
					parentDockerHubImages.get(j));
			for (int i = 1; i <= 100; i++) {
				Thread.sleep(delay);
				List<DockerProperties> dockersThisPage = getDockerImages(driver, url + i, parentDockerHubImages.get(j));

				dockers.addAll(dockersThisPage);
				System.out.println(String.format("Parent index:%d, %d out of 100 pages done", j + 1, i));
			}
			SaveDataToFile(dockers);
		}

		githubDriver.quit();
		driver.quit();
	}
}