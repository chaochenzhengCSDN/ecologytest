package weaver.iiot.grouptow.common;

import com.weaver.general.Util;
import weaver.conn.RecordSet;
import weaver.iiot.grouptow.util.AttendanceUtil;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class FinalTimeListController {
    AttendanceUtil attendanceUtil=new AttendanceUtil();
    public List<String> getFinalTimeList(List<String> timeList) {
        //调用getMorningTimeList(TreeSet<String> ts2)方法获取上午打卡时间集合
        List<String> morningTimeList = getMorningTimeList(timeList);

        //调用getAfternoonTimeList(TreeSet<String> ts2)方法获取下午打卡时间集合
        List<String> afternoonTimeList = getAfternoonTimeList(timeList);

        //调用getconfirmTimeList(List<String> afternoonTimeList)方法获取下午17:15之后的打卡时间集合
        List<String> confirmTimeList = getConfirmTimeList(afternoonTimeList);
        //遍历上午时段的打卡集合
        List<String> finalTimeList = new ArrayList<String>(morningTimeList);
        ////b.writeLog("上午数据："+finalTimeList);
        //遍历下午17:15时段之前的最终打卡集合
        List<String> finalAfternoonTimeList = getFinalAfternoonTimeList(afternoonTimeList);
        finalTimeList.addAll(finalAfternoonTimeList);
        ////b.writeLog("下午数据："+finalTimeList);
        //遍历下午时段17:15:00之后的时间集合
        List<String> finalCofirmTimeList = getFinalCofirmTimeList(confirmTimeList);
        finalTimeList.addAll(finalCofirmTimeList);
        ////b.writeLog("最终数据："+finalTimeList);
        return finalTimeList;
    }
    public  List<String> getFinalAfternoonTimeList(List<String> afternoonTimeList) {
        //定义下午17:15时段之前的最终打卡时间的集合
        List<String> finalAfternoonTimeList = new ArrayList<String>();
        ////b.writeLog("afternoonTimeList:"+afternoonTimeList);
        List<String> afternoonTimeList1=new ArrayList<String>();
        List<String> leaveTimeList=new ArrayList<String>();
        for(String cTime:afternoonTimeList){
            if(cTime.endsWith("1")||cTime.endsWith("2")){
                afternoonTimeList1.add(cTime);
            }else{
                leaveTimeList.add(cTime);
            }
        }
        ////b.writeLog("流程数据:"+leaveTimeList);
        for (int y = 0; y < afternoonTimeList1.size(); y++) {
            String time = afternoonTimeList1.get(y);
            String[] split1 = time.split(":");
            int hour = Integer.parseInt(split1[0]);
            int minute = Integer.parseInt(split1[1]);
            int seconds = Integer.parseInt(split1[2]);
            int typeInt = Integer.parseInt(split1[3]);
            ////b.writeLog("afternoonTimeList:"+afternoonTimeList);
            //1.2如果最后一次打卡在17:15:00之前，则取17:15:00之前的第一次打卡时间和最后一次打卡时间
            if ((afternoonTimeList1.size()) > 1 && y == (afternoonTimeList1.size() - 1) && ((hour < 17) || (hour == 17 && minute < 15 && seconds < 60))) {
                String time2 = afternoonTimeList1.get(y);
                //b.writeLog("time2:"+time2);
                finalAfternoonTimeList.add(time2);
                //b.writeLog("finalAfternoonTimeList:"+finalAfternoonTimeList);
                //1.3如果最后一次打卡在17:15:00之后则取下午时段的第一次打卡的时间和17:15:00之后打卡的时间
            }
            if ((y == 0 && typeInt == 1) || (y == 0 && afternoonTimeList1.size() == 1)) {
                finalAfternoonTimeList.add(time);
            }
        }
        for(String time2:leaveTimeList){
            int time2ForMin=Integer.parseInt(time2.split(":")[0])*60+Integer.parseInt(time2.split(":")[1]);
            if(time2ForMin<17*60+15){
                finalAfternoonTimeList.add(time2);
            }
        }
        Collections.sort(finalAfternoonTimeList);
        ////b.writeLog("17：15之前打卡时间为"+finalAfternoonTimeList);
        return finalAfternoonTimeList;
    }
    public List<String> getFinalCofirmTimeList(List<String> confirmTimeList) {
        //定义下午17:15时段之后的最终打卡时间的集合
        List<String> finalCofirmTimeList = new ArrayList<String>();
        //1.如果17:15:00之后的时间集合里只有一个数据，那就直接展示
        if (confirmTimeList.size() == 1) {
            String time = confirmTimeList.get(0);
            finalCofirmTimeList.add(time);
        }

        //2.如果17:15:00之后的时间集合里有两个数据，判断这两个数据是否相差30分钟
        if (confirmTimeList.size() == 2) {
            String time1 = confirmTimeList.get(0);
            int secondsTime1 = getTime(time1);
            String time2 = confirmTimeList.get(1);
            int secondsTime2 = getTime(time2);
            //2.1如果相差30分钟，则把这两个数据都展示出来
            if (secondsTime2 - secondsTime1 >= 1800) {
                finalCofirmTimeList.add(time1);
                finalCofirmTimeList.add(time2);
            } else {
                //2.2如果不相差30分钟，则把最后一个数据展示出来
                finalCofirmTimeList.add(time2);
            }
        }

        List<String> countList = new ArrayList<String>();
        //3.如果17:15:00之后的时间集合里有超过两个数据的
        if (confirmTimeList.size() > 2) {
            for (int z = 0; z < confirmTimeList.size(); z++) {
                if (z == 0) {
                    String time = confirmTimeList.get(z);
                    countList.add(time);
                } else {
                    if (finalCofirmTimeList.size() < 3) {
                        //3.1先取第一次打卡记录
                        String time1 = confirmTimeList.get(z - 1);
                        String time2 = confirmTimeList.get(z);
                        int secondsTime1 = getTime(time1);
                        int secondsTime2 = getTime(time2);
                        //3.2若存在30分钟后的打卡记录，则取第一次和30分钟后第一次的打卡记录
                        if (secondsTime2 - secondsTime1 >= 1800) {
                            String time = confirmTimeList.get(0);
                            finalCofirmTimeList.add(time);
                            finalCofirmTimeList.add(time2);
                            countList.add(time2);
                            if (confirmTimeList.size() - (z + 1) > 0) {
                                String time3 = confirmTimeList.get(confirmTimeList.size() - 1);
                                finalCofirmTimeList.add(time3);
                                countList.add(time3);
                            }
                        } else {
                            //3.3若不存在30分钟后的打卡记录，则取最后一次的打卡记录
                            if (z == (confirmTimeList.size() - 1) && countList.size() == 1) {
                                String time3 = confirmTimeList.get(confirmTimeList.size() - 1);
                                finalCofirmTimeList.add(time3);
                            }
                        }
                    }
                }
            }
        }
        return finalCofirmTimeList;
    }
    public  Integer getTime(String s){
        String [] arr = s.split(":");
        int hour = Integer.parseInt(arr[0]);
        int minute = Integer.parseInt(arr[1]);
        int seconds = Integer.parseInt(arr[2]);
        return hour*3600+minute*60+seconds;
    }
    public  List<String> getMorningTimeList(List<String> list) {
        //定义第一个集合，添加上午时段的打卡时间
        List<String> morningTimeList = new ArrayList<String>();
        //定义第二个集合，添加上午时段的上班卡时间
        List<String> morningUpTimeList = new ArrayList<String>();
        //定义第三个集合，添加上午时段的下班卡时间
        List<String> morningDownTimeList = new ArrayList<String>();
        //定义第四个集合，添加上午时段的打卡时间
        List<String> newmorningTimeList = new ArrayList<String>();
        for (String time : list) {
            String[] split1 = time.split(":");
            int hour = Integer.parseInt(split1[0]);
            int minute = Integer.parseInt(split1[1]);
            int seconds = Integer.parseInt(split1[2]);
            int typeInt = Integer.parseInt(split1[3]);
            if (0 <= hour && hour < 12 && 0 <= minute && minute < 60 && 0 <= seconds && seconds < 60) {
                if (typeInt == 1) {
                    morningUpTimeList.add(time);
                } else if (typeInt == 2) {
                    morningDownTimeList.add(time);
                }
                //2020.06.23 zcc
                else if (typeInt == 3 || typeInt == 4 || typeInt == 5 || typeInt == 6 || typeInt == 7 || typeInt == 8) {
                    morningTimeList.add(time);
                }
            }
        }
        //如果当天上午存在两次及以上，比较前一次请假的结束时间和下一次请假的开始时间20210126
        if(morningTimeList.size()>2){
            for(int i = 1; i < morningTimeList.size();i+=2){
                if((i+1) !=morningTimeList.size()){
                    if(attendanceUtil.getTimeMin(morningTimeList.get(i))>=attendanceUtil.getTimeMin(morningTimeList.get(i+1))){
                        newmorningTimeList.add(morningTimeList.get(i));
                        newmorningTimeList.add(morningTimeList.get(i+1));
                    }
                }
            }
        }
        morningTimeList.removeAll(newmorningTimeList);
        if (morningUpTimeList.size() > 0) {
            //获取上午上班卡最早的一个打卡时间
            String time = morningUpTimeList.get(0);
            morningTimeList.add(time);
        }
        if (morningDownTimeList.size() > 0) {
            //获取上午下班卡最晚的一个打卡时间
            String time = morningDownTimeList.get((morningDownTimeList.size()) - 1);
            morningTimeList.add(time);
        }
        Collections.sort(morningTimeList);
        ////b.writeLog("当天上午打卡记录："+morningTimeList);
        return morningTimeList;
    }
    public  List<String> getAfternoonTimeList(List<String> list) {
        //定义第一个集合，添加下午时段的打卡时间
        List<String> afternoonTimeList = new ArrayList<String>();
        //定义第二个集合，添加下午时段的上班卡时间
        List<String> afternoonUpTimeList = new ArrayList<String>();
        //定义第三个集合，添加下午时段的下班卡时间
        List<String> afternoonDownTimeList = new ArrayList<String>();
        //接收不符合规则的请假数据(两次及以上请假)
        List<String> newafternoonTimeList = new ArrayList<String>();
        for (String time : list) {
            String[] split1 = time.split(":");
            int hour = Integer.parseInt(split1[0]);
            int minute = Integer.parseInt(split1[1]);
            int seconds = Integer.parseInt(split1[2]);
            int typeInt = Integer.parseInt(split1[3]);
            if (12 <= hour && hour < 24 && 0 <= minute && minute < 60 && 0 <= seconds && seconds < 60) {
                if (typeInt == 1) {
                    afternoonUpTimeList.add(time);
                } else if (typeInt == 2) {
                    afternoonDownTimeList.add(time);
                }
                //2020.06.23 zcc
                else if (typeInt == 3 || typeInt == 4 || typeInt == 5 || typeInt == 6 || typeInt == 7 || typeInt == 8) {
                    afternoonTimeList.add(time);
                }
            }
        }
        //如果当天上午存在两次及以上，比较前一次请假的结束时间和下一次请假的开始时间20210126
        if(afternoonTimeList.size()>2){
            for(int i = 1; i < afternoonTimeList.size();i+=2){
                if((i+1) !=afternoonTimeList.size()){
                    if(attendanceUtil.getTimeMin(afternoonTimeList.get(i))>=attendanceUtil.getTimeMin(afternoonTimeList.get(i+1))){
                        newafternoonTimeList.add(afternoonTimeList.get(i));
                        newafternoonTimeList.add(afternoonTimeList.get(i+1));
                    }
                }
            }
        }
        afternoonTimeList.removeAll(newafternoonTimeList);
        if (afternoonUpTimeList.size() > 0) {
            //获取下午上班卡最早的一个打卡时间
            String time = afternoonUpTimeList.get(0);
            afternoonTimeList.add(time);
        }
        if (afternoonDownTimeList.size() > 0) {
            //遍历下午下班卡
            afternoonTimeList.addAll(afternoonDownTimeList);
        }
        Collections.sort(afternoonTimeList);
        return afternoonTimeList;
    }
    public  List<String> getConfirmTimeList(List<String> afternoonTimeList) {
        List<String> confirmTimeList = new ArrayList<String>();
        for (int y = 0; y < afternoonTimeList.size(); y++) {
            String time = afternoonTimeList.get(y);
            String[] split1 = time.split(":");
            int hour = Integer.parseInt(split1[0]);
            int minute = Integer.parseInt(split1[1]);
            int seconds = Integer.parseInt(split1[2]);
            int typeInt = Integer.parseInt(split1[3]);
            if ((y == 0 && typeInt == 1) || (y == 0 && afternoonTimeList.size() == 1)) {

            } else {
                if ((hour > 17) || (hour == 17 && minute >= 15 && seconds < 60 && seconds >= 0)) {
                    confirmTimeList.add(time);
                }
            }
        }
        ////b.writeLog("当天打卡记录:"+confirmTimeList);
        return confirmTimeList;
    }

    public static List<String> reviseFinalTimeList(List<String> finalTimeList, String curdate, String id) {
        List<String> newFinalTimeList = new ArrayList<String>();//定义结合接收修正后的数据
        //查询该用户拥有的哺乳假
        String getLactationSql = "SELECT start_date,end_date,morning_sign_in,morning_sign_back,afternoon_sign_in,afternoon_sign_back from uf_lactation where userid='" + id + "' ";
        RecordSet getLactationRs = new RecordSet();
        getLactationRs.execute(getLactationSql);
        while (getLactationRs.next()) {
            String startDate = Util.null2String(getLactationRs.getString("start_date"));//哺乳假的开始日期
            String endDate = Util.null2String(getLactationRs.getString("end_date"));//哺乳假的结束日期
            String morningSignIn = Util.null2String(getLactationRs.getString("morning_sign_in"));//上午签到
            String morningSignBack = Util.null2String(getLactationRs.getString("morning_sign_back"));//上午签退
            String afternoonSignIn = Util.null2String(getLactationRs.getString("afternoon_sign_in"));//下午签到
            String afternoonSignBack = Util.null2String(getLactationRs.getString("afternoon_sign_back"));//下午签退
            //哺乳假1天1次，每次1小时
            boolean result1 = (("1").equals(morningSignIn)) && (("0").equals(morningSignBack)) && (("0").equals(afternoonSignIn)) && (("0").equals(afternoonSignBack));//上午签到1小时
            boolean result2 = (("0").equals(morningSignIn)) && (("1").equals(morningSignBack)) && (("0").equals(afternoonSignIn)) && (("0").equals(afternoonSignBack));//上午签退1小时
            boolean result3 = (("0").equals(morningSignIn)) && (("0").equals(morningSignBack)) && (("1").equals(afternoonSignIn)) && (("0").equals(afternoonSignBack));//下午签到1小时
            boolean result4 = (("0").equals(morningSignIn)) && (("0").equals(morningSignBack)) && (("0").equals(afternoonSignIn)) && (("1").equals(afternoonSignBack));//下午签退1小时
            //哺乳假1天2次，每次0.5小时
            boolean result5 = (("1").equals(morningSignIn)) && (("1").equals(morningSignBack)) && (("0").equals(afternoonSignIn)) && (("0").equals(afternoonSignBack));//上午签到 上午签退
            boolean result6 = (("1").equals(morningSignIn)) && (("0").equals(morningSignBack)) && (("1").equals(afternoonSignIn)) && (("0").equals(afternoonSignBack));//上午签到 下午签到
            boolean result7 = (("1").equals(morningSignIn)) && (("0").equals(morningSignBack)) && (("0").equals(afternoonSignIn)) && (("1").equals(afternoonSignBack));//上午签到 下午签退
            boolean result8 = (("0").equals(morningSignIn)) && (("1").equals(morningSignBack)) && (("1").equals(afternoonSignIn)) && (("0").equals(afternoonSignBack));//上午签退 下午签到
            boolean result9 = (("0").equals(morningSignIn)) && (("1").equals(morningSignBack)) && (("0").equals(afternoonSignIn)) && (("1").equals(afternoonSignBack));//上午签退 下午签退
            boolean result10 = (("0").equals(morningSignIn)) && (("0").equals(morningSignBack)) && (("1").equals(afternoonSignIn)) && (("1").equals(afternoonSignBack));//下午签到 下午签退
            //比较打卡日期 在哺乳假开始日期与结束日期之间
            if (startDate.compareTo(curdate) <= 0 && endDate.compareTo(curdate) >= 0) {
                //b.writeLog("开始修正符合条件的数据,当前日期为:"+curdate+",哺乳假开始日期:"+startDate+",哺乳假开始日期:"+endDate);
                for (String time : finalTimeList) {
                    //上午签到晚1小时
                    if (result1) {
                        //取出上午签到时间
                        if (time.endsWith("1") && (Integer.parseInt(time.substring(0, 2)) < 12)) {
                            time = (Integer.parseInt(time.substring(0, 2)) - 1) <= 9 ? ("0" + (Integer.parseInt(time.substring(0, 2)) - 1)) + time.substring(2) : ((Integer.parseInt(time.substring(0, 2)) - 1)) + time.substring(2);
                            time = time.compareTo("08:30:00:1") >= 0 ? time : "08:30:00:1";//修正后的时间如果小于08：30，则取08：30
                        }
                    }
                    //上午签退早1小时
                    if (result2) {
                        //取出上午签退时间
                        if (time.endsWith("2") && (Integer.parseInt(time.substring(0, 2)) < 12)) {
                            time = ((Integer.parseInt(time.substring(0, 2)) + 1) <= 9 ? ("0" + (Integer.parseInt(time.substring(0, 2)) + 1)) + time.substring(2) : (String.valueOf(Integer.parseInt(time.substring(0, 2)) + 1))) + time.substring(2);
                            time = time.compareTo("11:45:00:2") <= 0 ? time : "11:45:00:2";//修正后的时间如果大于11:45，则取11:45
                        }
                    }
                    //下午签到晚1小时
                    if (result3) {
                        //取出下午签退时间
                        if (time.endsWith("1") && (Integer.parseInt(time.substring(0, 2)) >= 12)) {
                            time = ((Integer.parseInt(time.substring(0, 2)) - 1) <= 9 ? ("0" + (Integer.parseInt(time.substring(0, 2)) - 1)) + time.substring(2) : (String.valueOf(Integer.parseInt(time.substring(0, 2)) - 1))) + time.substring(2);
                            time = time.compareTo("13:00:00:1") >= 0 ? time : "13:00:00:1";//修正后的时间如果大于13:00，则取13:00
                        }
                    }
                    //下午签退早1小时
                    if (result4) {
                        //取出下午签退时间
                        if (time.endsWith("2") && (Integer.parseInt(time.substring(0, 2)) >= 12)) {
                            time = ((Integer.parseInt(time.substring(0, 2)) + 1) <= 9 ? ("0" + (Integer.parseInt(time.substring(0, 2)) + 1)) + time.substring(2) : (String.valueOf(Integer.parseInt(time.substring(0, 2)) + 1))) + time.substring(2);
                            time = time.compareTo("17:15:00:2") <= 0 ? time : "17:15:00:2";//修正后的时间如果大于17:15，则取17:15
                        }
                    }
                    //上午签到 上午签退 各半小时
                    if (result5) {
                        //取出上午签到时间
                        if (time.endsWith("1") && (Integer.parseInt(time.substring(0, 2)) < 12)) {
                            time = getBeforeHalfHour(time);//算出半小时前的数据
                            time = time.compareTo("08:30:00:1") >= 0 ? time : "08:30:00:1";//修正后的时间如果小于08：30，则取08：30
                        }
                        //取出上午签退时间
                        if (time.endsWith("2") && (Integer.parseInt(time.substring(0, 2)) < 12)) {
                            time = getHalfHour(time);//算出后小时后的数据
                            time = time.compareTo("11:45:00:2") <= 0 ? time : "11:45:00:2";//修正后的时间如果大于11:45，则取11:45
                        }
                    }
                    //上午签到 下午签到 各半小时
                    if (result6) {
                        //取出上午签到时间
                        if (time.endsWith("1") && (Integer.parseInt(time.substring(0, 2)) < 12)) {
                            time = getBeforeHalfHour(time);//算出半小时前的数据
                            time = time.compareTo("08:30:00:1") >= 0 ? time : "08:30:00:1";//修正后的时间如果小于08：30，则取08：30
                        }
                        //取出下午签到时间
                        if (time.endsWith("1") && (Integer.parseInt(time.substring(0, 2)) >= 12)) {
                            time = getBeforeHalfHour(time);//算出半小时前的数据
                            time = time.compareTo("13:00:00:1") >= 0 ? time : "13:00:00:1";//修正后的时间如果大于13:00，则取13:00
                        }
                    }
                    //上午签到 下午签退 各半小时
                    if (result7) {
                        //取出上午签到时间
                        if (time.endsWith("1") && (Integer.parseInt(time.substring(0, 2)) < 12)) {
                            time = getBeforeHalfHour(time);//算出半小时前的数据
                            time = time.compareTo("08:30:00:1") >= 0 ? time : "08:30:00:1";//修正后的时间如果大于08：30，则取08：30
                        }
                        //取出下午签退时间
                        if (time.endsWith("2") && (Integer.parseInt(time.substring(0, 2)) >= 12)) {
                            time = getHalfHour(time);//算出后小时后的数据
                            time = time.compareTo("17:15:00:2") <= 0 ? time : "17:15:00:2";//修正后的时间如果小于17:15，则取17:15
                        }
                    }
                    //上午签退 下午签到 各半小时
                    if (result8) {
                        //取出上午签退时间
                        if (time.endsWith("2") && (Integer.parseInt(time.substring(0, 2)) < 12)) {
                            time = getHalfHour(time);//算出半小时后的数据
                            time = time.compareTo("11:45:00:2") <= 0 ? time : "11:45:00:2";//修正后的时间如果大于11:45，则取11:45
                        }
                        //取出下午签到时间
                        if (time.endsWith("1") && (Integer.parseInt(time.substring(0, 2)) >= 12)) {
                            time = getBeforeHalfHour(time);//算出半小时前的数据
                            time = time.compareTo("13:00:00:1") >= 0 ? time : "13:00:00:1";//修正后的时间如果大于13:00，则取13:00
                        }
                    }
                    //上午签退 下午签退 各半小时
                    if (result9) {
                        //取出上午签退时间
                        if (time.endsWith("2") && (Integer.parseInt(time.substring(0, 2)) < 12)) {
                            time = getHalfHour(time);
                            time = time.compareTo("11:45:00:2") <= 0 ? time : "11:45:00:2";//修正后的时间如果大于11:45，则取11:45
                        }
                        //取出下午签退时间
                        if (time.endsWith("2") && (Integer.parseInt(time.substring(0, 2)) >= 12)) {
                            time = getHalfHour(time);//算出半小时后的数据
                            time = time.compareTo("17:15:00:2") <= 0 ? time : "17:15:00:2";//修正后的时间如果大于17:15，则取17:15
                        }
                    }
                    //下午签到 下午签退 各半小时
                    if (result10) {
                        //取出下午签到时间
                        if (time.endsWith("1") && (Integer.parseInt(time.substring(0, 2)) >= 12)) {
                            time = getBeforeHalfHour(time);//算出半小时前的数据
                            time = time.compareTo("13:00:00:1") >= 0 ? time : "13:00:00:1";//修正后的时间如果大于13:00，则取13:00
                        }
                        //取出下午签退时间
                        if (time.endsWith("2") && (Integer.parseInt(time.substring(0, 2)) >= 12)) {
                            time = getHalfHour(time);//算出半小时后的数据
                            time = time.compareTo("17:15:00:2") <= 0 ? time : "17:15:00:2";//修正后的时间如果大于17:15，则取17:15
                        }
                    }
                    newFinalTimeList.add(time);//将数据重新放入新的集合中
                }
            }
        }
        if (newFinalTimeList.size() == 0) {
            newFinalTimeList = finalTimeList;
        }
        return newFinalTimeList;
    }

    public static String getBeforeHalfHour(String curTime) {
        int hour1 = Integer.parseInt(curTime.substring(0, 2));
        int minute1 = Integer.parseInt(curTime.substring(3, 5));
        String time3 = ((hour1) <= 9 ? ("0" + hour1) : (String.valueOf(hour1))) + ":" +
                ((minute1 - 30 <= 9) ? ("0" + (minute1 - 30)) : (String.valueOf(minute1 - 30))) + curTime.substring(5);
        String time4 = ((hour1 - 1) <= 9 ? ("0" + (hour1 - 1)) : (String.valueOf(hour1 - 1))) + ":" +
                ((minute1 + 30 <= 9) ? ("0" + (minute1 + 30)) : (String.valueOf(minute1 + 30))) + curTime.substring(5);
        return minute1 >= 30 ? time3 : time4;
    }

    public static String getHalfHour(String time) {
        int hour = Integer.parseInt(time.substring(0, 2));
        int minute = Integer.parseInt(time.substring(3, 5));
        String time1 = ((hour + 1) <= 9 ? ("0" + (hour + 1)) : (String.valueOf(hour + 1))) + ":" +
                ((minute - 30 <= 9) ? ("0" + (minute - 30)) : (String.valueOf(minute - 30))) + time.substring(5);
        String time2 = ((hour) <= 9 ? ("0" + hour) : (String.valueOf(hour))) + ":" +
                ((minute + 30 <= 9) ? ("0" + (minute + 30)) : (String.valueOf(minute + 30))) + time.substring(5);
        return minute >= 30 ? time1 : time2;
    }
}