import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.InetSocketAddress;
import java.net.Proxy;
import java.net.URL;
import java.net.URLConnection;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import org.json.JSONArray;
import org.json.JSONObject;
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;

public class DockerHubApiInvoker {

	public static void main(String[] args) throws IOException, InterruptedException {

		List<ProxyServer> proxyServers = GetProxyAddresses();

		String officialImage = args[0];
		int numberOfThreads = Integer.parseInt(args[1]);
		List<String> images = SearchImages(officialImage);
		ExecutorService executor = Executors.newFixedThreadPool(numberOfThreads);

		int numberOfItemsPerThread = images.size() / numberOfThreads;

		for (int i = 0; i < numberOfThreads; i++) {
			CustomRunnable customRunnable = new CustomRunnable(officialImage,
					images.subList(i * numberOfItemsPerThread, (i + 1) * numberOfItemsPerThread), proxyServers);
			executor.submit(customRunnable);
		}

		executor.shutdown();
		// executor.awaitTermination(1, TimeUnit.HOURS);
	}

	private static List<String> SearchImages(String officialImageName) throws IOException {

		List<String> images = new ArrayList<String>();
		int number_of_pages = 1;
		for (int i = 1; i <= number_of_pages; i++) {

			System.out.println("Page " + i + " out of " + number_of_pages);

			String url = "https://index.docker.io/v1/search?q=%s&page=%s&n=100";

			URL imageSearchUrl = new URL(String.format(url, officialImageName, i));
			URLConnection connection = imageSearchUrl.openConnection();
			BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(connection.getInputStream()));
			String response = bufferedReader.readLine();

			bufferedReader.close();

			JSONObject jsonObject = new JSONObject(response);
			number_of_pages = jsonObject.getInt("num_pages");

			JSONArray results = jsonObject.getJSONArray("results");

			for (int j = 0; j < results.length(); j++) {
				JSONObject imageObject = results.getJSONObject(j);
				images.add(imageObject.getString("name"));
			}
		}
		return images;
	}

	private static List<ProxyServer> GetProxyAddresses() {

/*		System.setProperty("webdriver.chrome.driver", "chromedriver");
		ChromeOptions chromeOptions = new ChromeOptions();
		chromeOptions.addArguments("--headless");
		chromeOptions.addArguments("--no-sandbox");
		WebDriver driver = new ChromeDriver(chromeOptions);*/
		List<ProxyServer> proxyServers = new ArrayList<ProxyServer>();
		
		try {
			String url = "https://www.proxy-list.download/api/v1/get?type=http&anon=elite";
/*			driver.get(url);
			String proxies = driver.findElement(By.tagName("html")).getText();*/
			
			URL proxyListApiUrl = new URL(url);
			HttpURLConnection connection = (HttpURLConnection)proxyListApiUrl.openConnection();
			connection.addRequestProperty("Accept", "text/html; charset=utf-8");
			connection.addRequestProperty("User-Agent", 
					"Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.0)");
			connection.setDoOutput(true);
			connection.setRequestMethod("GET");
			BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(connection.getInputStream()));

			String line;
			while((line = bufferedReader.readLine()) != null) {
				String[] addressSplit = line.split(":");
				proxyServers.add(new ProxyServer(addressSplit[0], addressSplit[1]));
			}
			return proxyServers;
		}catch(Exception e){
			System.out.println("Error getting proxy servers!");
		}
		return null;
		
	}
}
