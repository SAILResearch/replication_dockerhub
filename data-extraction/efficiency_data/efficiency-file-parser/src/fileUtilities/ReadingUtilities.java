package fileUtilities;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.ObjectInputStream;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;

public class ReadingUtilities {

	public static List<String> getLines (String pFile) {
		List<String> vListLines = new LinkedList<String>();

		BufferedReader fileBuffer = null;
		try {

			fileBuffer = new BufferedReader(new FileReader(pFile));

			String line;

			while ((line = fileBuffer.readLine()) != null) {
				vListLines.add(line);
			}

		} catch (Exception e) {
		}
		return vListLines;
	}

	public static List<String> getElements (String pDirectory) {

		List<String> vResult = new LinkedList<String>();
		File f = new File(pDirectory);

		if (f.isDirectory()) {
			for (File fileOrFolder : f.listFiles()) {
				vResult.add(fileOrFolder.toString());
			} 
		}
		return vResult;
	}

	public static List<String> getFolders (String pDirectory) {

		List<String> vResult = new LinkedList<String>();
		File f = new File(pDirectory);

		if (f.isDirectory()) {
			for (File fileOrFolder : f.listFiles()) {
				if (fileOrFolder.isDirectory()) {
					vResult.add(fileOrFolder.toString());
				} 
			} 
		}
		return vResult;
	}

	public static List<String> getFoldersAndSubFolders (String pDirectory) {

		List<String> vResult = new LinkedList<String>();
		File f = new File(pDirectory);

		if (f.isDirectory()) {
			for (File fileOrFolder : f.listFiles()) {
				if (fileOrFolder.isDirectory()) {
					vResult.addAll(getFoldersAndSubFolders(fileOrFolder.toString()));
				} else {
					vResult.add(fileOrFolder.toString());
				}
			} 
		}
		return vResult;
	}

	public static Map desserializeMap (String file) {
		FileInputStream fis;
		Map anotherMap = null;
		try {
			fis = new FileInputStream(file + ".ser");
			ObjectInputStream ois = new ObjectInputStream(fis);
			anotherMap = (Map) ois.readObject();
			ois.close();
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		return anotherMap;
	}
	
	public static List desserializeList (String file) {
		FileInputStream fis;
		List anotherMap = null;
		try {
			fis = new FileInputStream(file + ".ser");
			ObjectInputStream ois = new ObjectInputStream(fis);
			anotherMap = (List) ois.readObject();
			ois.close();
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		return anotherMap;
	}

}
