import java.util.LinkedList;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;

/**
 * @author zcc
 * @version V1.0
 * @Title:
 * @Description: xxx模块接口
 * @date 2020/10/23 9:41
 */
public class Demo {
    public static void main(String[] args) {
        List<String> list=new LinkedList<String>();
        list.add("1");
        list.add("2");
        System.out.println("list = " + list);
        list.remove("1");
        System.out.println("list = " + list);
        list.remove("2");
        System.out.println("list = " + list);

        ConcurrentHashMap<String, String> stringStringConcurrentHashMap = new ConcurrentHashMap<String, String>();
        stringStringConcurrentHashMap.put("1","sdsad");
        System.out.println("stringStringConcurrentHashMap = " + stringStringConcurrentHashMap);
        String s = stringStringConcurrentHashMap.get("2");
        System.out.println("s = " + s);
    }
}
