public class DockerProperties implements Comparable<DockerProperties>{

		public DockerProperties(String parentDockerImageName, String link, String name, int numberOfStars, 
				int numberOfPulls, String gitUrl, int isOfficial) {
			this.name = name;
			this.numberOfStars = numberOfStars;
			this.numberOfPulls = numberOfPulls;
			this.link = link;
			this.gitUrl = gitUrl;
			this.isOffcial = isOfficial; 
			this.parentDockerImageName = parentDockerImageName;
		}
		
		public String parentDockerImageName;
		public String name;
		public int numberOfStars;
		public int numberOfPulls;
		public String link;
		public String gitUrl;
		public int isOffcial;
		
		public String getRow() {
			return this.link + "," + this.name + "," + this.numberOfPulls
			+ "," + this.numberOfPulls + "," + this.gitUrl;
		}
		
		@Override
		public int compareTo(DockerProperties properties) {
			if(this.numberOfStars > properties.numberOfStars) return -1;
			return 1;
		}
	}
