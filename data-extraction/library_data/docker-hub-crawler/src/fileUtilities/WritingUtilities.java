package fileUtilities;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectOutputStream;
import java.io.PrintWriter;
import java.util.List;
import java.util.Map;

public class WritingUtilities {


	public static void writeLines (String pFileName, List<String> pLines ) {

		PrintWriter writer;
		try {
			writer = new PrintWriter(new FileOutputStream(
				    new File(pFileName), 
				    true)); 

			for (String string : pLines) {
				writer.println(string);
			}

			writer.close();
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	public static void writeLine (String pFileName, StringBuffer pLine ) {

		PrintWriter writer;
		try {
			writer = new PrintWriter(pFileName);

			writer.println(pLine);

			writer.close();
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	public static void serializeMap (String file, Map map) {
		try
		{
			FileOutputStream fos = new FileOutputStream(file + ".ser");
			ObjectOutputStream oos = new ObjectOutputStream(fos);
			oos.writeObject(map);
			oos.close();
			fos.close();

		}catch(IOException ioe)
		{
			ioe.printStackTrace();
		}
	}

	public static void serializeList(String file, List traceLines) {
		try
		{
			FileOutputStream fos = new FileOutputStream(file + ".ser");
			ObjectOutputStream oos = new ObjectOutputStream(fos);
			oos.writeObject(traceLines);
			oos.close();
			fos.close();

		}catch(IOException ioe)
		{
			ioe.printStackTrace();
		}		
	}



}
