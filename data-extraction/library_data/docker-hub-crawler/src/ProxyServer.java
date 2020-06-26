class ProxyServer {
		public ProxyServer(String ipAddress, String portNumber) {
			this.ipAddress = ipAddress;
			this.portNumber = Integer.parseInt(portNumber);
		}
		public String ipAddress;
		public int  portNumber;
	}
