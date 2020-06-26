import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.URL;
import java.net.URLConnection;
import java.util.LinkedList;
import java.util.List;
import java.util.Random;
import org.json.JSONArray;
import org.json.JSONObject;
import java.net.InetSocketAddress;
import java.net.Proxy;

import fileUtilities.WritingUtilities;

public class CustomRunnable implements Runnable {

	public CustomRunnable(String officialImage, List<String> images, List<ProxyServer> proxyServers) {
		this.officialImage = officialImage;
		this.images = images;
		this.proxyServers = proxyServers;
	}

	private String officialImage;
	private List<String> images;
	private int id = 0;
	private List<ProxyServer> proxyServers;

	public void SaveDataToFile(List<ImageTag> tags) {
		List<String> data = new LinkedList<>();
		for (int i = 0; i < tags.size(); i++) {
			ImageTag tag = tags.get(i);
			data.add(tag.officialImageName + "," + tag.imageName + "," + tag.tagName + "," + tag.size + ","
					+ tag.lastUpdateDate);
		}
		if (id == 0) {
			Random rand = new Random();
			id = rand.nextInt(100);
		}

		WritingUtilities.writeLines(String.format("docker_hub_images_for_%s_%s.csv", officialImage, id), data);
	}

	@Override
	public void run() {
		try {
			List<ImageTag> imageTags = GetTagInfo(images, officialImage);
			SaveDataToFile(imageTags);
		} catch (IOException e) {
			// TODO Auto-generated catch block
			System.out.println("Tag info failed for " + id);
			e.printStackTrace();
		}
		System.out.println("Done: " + id);
	}

	private List<ImageTag> GetTagInfo(List<String> images, String officialImage) throws IOException {

		List<ImageTag> tags = new LinkedList<ImageTag>();

		for (int j = 0; j < images.size(); j++) {

			System.out.println("item " + (j + 1) + " of " + images.size() + " thread id: " + id);
			String currentOfficialImageName = officialImage;
			String currentImageName = images.get(j);

			if (!currentImageName.contains("/")) {
				currentImageName = "library/" + currentImageName;
			}

			String urlPattern = "https://registry.hub.docker.com/v2/repositories/%s/tags";
			String url = String.format(urlPattern, currentImageName);

			String nextUrl = url;

			while (!nextUrl.isEmpty()) {

				String allTags = "";
				BufferedReader bufferedReader = null;

				try {
					Random random = new Random();
					ProxyServer proxyServer = proxyServers.get(random.nextInt(proxyServers.size() -1));
					URL imageSearchUrl = new URL(url);
					Proxy proxy = new Proxy(Proxy.Type.HTTP,
							new InetSocketAddress(proxyServer.ipAddress, proxyServer.portNumber));
					URLConnection connection = imageSearchUrl.openConnection(proxy);
					connection.setConnectTimeout(60000);
					bufferedReader = new BufferedReader(new InputStreamReader(connection.getInputStream()));
					allTags = bufferedReader.readLine();
				} catch (Exception e) {
					System.out.println("Timeout exception in thread: " + id);

					// Thread.sleep(300000);
                    
					bufferedReader.close();
					continue;
				} finally {
					bufferedReader.close();
				}

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
						// System.out.println("Exception in name!");
					}

					int size = 0;
					try {
						size = tagElement.getInt("full_size");
					} catch (Exception e) {
						// System.out.println("Exception in size!");
					}

					String lastUpdateDate = "";

					try {
						lastUpdateDate = tagElement.getString("last_updated");
					} catch (Exception e) {
						// System.out.println("Exception in date!");
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
			if (j % 100 == 0) {
				SaveDataToFile(tags);
				tags = new LinkedList<ImageTag>();
			}
		}
		return tags;
	}
}
