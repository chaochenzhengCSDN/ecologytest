package weaver.iiot.grouptow.common;

import com.weaver.general.Util;
import weaver.conn.RecordSet;
import weaver.general.BaseBean;
import weaver.iiot.grouptow.util.AttendanceUtil;

import java.util.*;

public class LeaveCommonController {
    AttendanceUtil attendanceUtil=new AttendanceUtil();
    public void changeLeaveTime(Map<String, List<String>> value, String id, String likeDate, int type, String leaveinFlag, String leaveoutFlag) {
        BaseBean b = new BaseBean();
        //全天标准打卡数据
        List<String> timeList1 = new ArrayList<String>();
        timeList1.add("08:30:00:" + leaveinFlag);
        timeList1.add("11:45:00:" + leaveoutFlag);
        timeList1.add("13:00:00:" + leaveinFlag);
        timeList1.add("17:15:00:" + leaveoutFlag);
        //上午上班、上午下班标准打卡数据
        List<String> timeList6 = new ArrayList<String>();
        timeList6.add("08:30:00:" + leaveinFlag);
        timeList6.add("11:45:00:" + leaveoutFlag);
        timeList6.add("13:00:00:" + leaveinFlag);
        timeList6.add("16:15:00:" + leaveoutFlag);

        String sql = "SELECT start_date,start_time,end_date,end_time from uf_AskForLeave WHERE type = " + type + " AND userid = " + id + " and " +
                "(start_date like '%" + likeDate + "%' or end_date like '%" + likeDate + "%') ORDER BY start_date";
        RecordSet rs = new RecordSet();
        rs.execute(sql);
        while (rs.next()) {
            //调休(年假)请假开始日期
            String startDate = Util.null2String(rs.getString("start_date"));
            //调休(年假)请假结束日期
            String endDate = Util.null2String(rs.getString("end_date"));
            //调休(年假)请假开始时间
            String startTime = Util.null2String(rs.getString("start_time"));
            //调休(年假)请假结束时间
            String endTime = Util.null2String(rs.getString("end_time"));
            if(!startDate.contains(likeDate)){
                startDate = likeDate+"-01";
                startTime = "08:30";
            }
            if(!endDate.contains(likeDate)){
                endDate = attendanceUtil.getEndDate(likeDate);
                endTime = "17:15";
            }
            List<String> wholeDate=attendanceUtil.findDates(startDate,endDate);
            b.writeLog(startDate+">>"+endDate+">>"+startTime+">>"+endTime);
            //请假日期不仅包括开始日期、结束日期，还包含其他日期 则需要对中间日期进行处理
            if(wholeDate.size()>2){
                for (String valueDate : wholeDate) {
                    String attendancestatus = attendanceUtil.getAttendanceStatus(valueDate).getAttendanceStatus();
                    //如果当天不为起始日期，也不为截止日期
                    if(!valueDate.equals(startDate)&&!valueDate.equals(endDate)){
                        if (attendancestatus.startsWith("0")) {
                            //正常出勤1天
                            value.put(valueDate, timeList1);
                        } else if (attendancestatus.startsWith("2")) {
                            //单休六出勤半天
                            value.put(valueDate, timeList6);
                        }
                    }else
                        //如果当天为起始日期
                        if(valueDate.equals(startDate)&&!valueDate.equals(endDate)){
                            if (attendancestatus.startsWith("0")) {
                                //正常出勤1天
                                String startTime1=startTime;
                                String endTime1 = "17:15";
                                changeTodayTime(value, startTime1, endTime1, startDate, leaveinFlag, leaveoutFlag);
                            } else if (attendancestatus.startsWith("2")) {
                                //单休六出勤半天
                                String startTime1=startTime;
                                String endTime1 = "16:15";
                                changeSaturdayTime(value, startTime1, endTime1, startDate, leaveinFlag, leaveoutFlag);
                            }
                        }else
                            //如果当天为截止日期
                            if(!valueDate.equals(startDate)&&valueDate.equals(endDate)){
                                if (attendancestatus.startsWith("0")) {
                                    //正常出勤1天
                                    String startTime1="08:30";
                                    String endTime1 = endTime.compareTo("17:15") >= 0 ? "17:15" : endTime;
                                    changeTodayTime(value, startTime1, endTime1, endDate, leaveinFlag, leaveoutFlag);
                                } else if (attendancestatus.startsWith("2")) {
                                    //单休六出勤半天
                                    String startTime1="08:30";
                                    String endTime1 = endTime.compareTo("16:15") >= 0 ? "16:15" : endTime;
                                    changeSaturdayTime(value, startTime1, endTime1, endDate, leaveinFlag, leaveoutFlag);
                                }
                            }
                }
            }else
                //请假开始日期和请假结束日期不为同一天
                if (wholeDate.size()==2) {
                    //----2020.07.13---start---
                    //处理调休(年假)请假开始当天的考勤打卡时间
                    String startDateStatus = attendanceUtil.getAttendanceStatus(startDate).getAttendanceStatus();
                    if (startDateStatus.startsWith("0")) {
                        //正常出勤1天
                        String startTime1=startTime;
                        String endTime1 = "17:15";
                        //b.writeLog("startDate:"+startDate);
                        changeTodayTime(value, startTime1, endTime1, startDate, leaveinFlag, leaveoutFlag);
                    } else if (startDateStatus.startsWith("2")) {
                        //单休六出勤半天
                        String startTime1=startTime;
                        String endTime1 = "16:15";
                        changeSaturdayTime(value, startTime1, endTime1, startDate, leaveinFlag, leaveoutFlag);
                    }
                    //调休(年假)请假结束日期当天的打卡记录集合
                    String endDateStatus = attendanceUtil.getAttendanceStatus(endDate).getAttendanceStatus();
                    if (endDateStatus.startsWith("0")) {
                        //正常出勤1天
                        String startTime1="08:30";
                        String endTime1 = endTime.compareTo("17:15") >= 0 ? "17:15" : endTime;
                        changeTodayTime(value, startTime1, endTime1, endDate, leaveinFlag, leaveoutFlag);
                    } else if (endDateStatus.startsWith("2")) {
                        //单休六出勤半天
                        String startTime1="08:30";
                        String endTime1 = endTime.compareTo("16:15") >= 0 ? "16:15" : endTime;
                        changeSaturdayTime(value, startTime1, endTime1, endDate, leaveinFlag, leaveoutFlag);
                    }
                    //----2020.07.13---end---
                } else if (wholeDate.size()==1){
                    //请假开始日期和请假结束日期为同一天
                    String attendancestatus = attendanceUtil.getAttendanceStatus(endDate).getAttendanceStatus();
                    if (attendancestatus.startsWith("0")) {
                        changeTodayTime(value, startTime, endTime, startDate, leaveinFlag, leaveoutFlag);//正常出勤1天
                    } else if (attendancestatus.startsWith("2")) {
                        changeSaturdayTime(value, startTime, endTime, startDate, leaveinFlag, leaveoutFlag);//单休六出勤半天
                    }
                }
        }
    }
    public void changeTodayTime(Map<String, List<String>> value, String startTime, String endTime, String outdate,String leaveinFlag,String leaveoutFlag) {
        List<String> gooutStartDate=new LinkedList<String>();
        //定义一个空集合处理请假数据
        List<String> leaveList=new LinkedList<String>();
        //如果打卡集合中包含当天打卡记录 则获取当天打卡数据
        if(value.containsKey(outdate)){
            gooutStartDate = value.get(outdate);
            Collections.sort(gooutStartDate);
        }
        int isNumber=gooutStartDate.size();//集合是否为空

        int endTimeForHours = Integer.parseInt(endTime.split(":")[0]);
        int endTimeForMinutes = Integer.parseInt(endTime.split(":")[1]);

        //修改zcc 2020.06.20 ---start---
        startTime=startTime+":00:"+leaveinFlag;//将请假开始时间变成打卡签到时间
        startTime=startTime.compareTo("08:30:00:"+leaveinFlag)<=0?("08:30:00:"+leaveinFlag):startTime;
        endTime=endTime+":00:"+leaveoutFlag;//将请假结束时间变成打卡签退时间
        endTime=endTime.compareTo("17:15:00:"+leaveoutFlag)>=0?("17:15:00:"+leaveoutFlag):endTime;

        //前提（结束时间一定大于开始时间）
        //2.外出开始时间小于等于8:30,外出结束时间小于11:45
        boolean result2 = getTimeMin(startTime) <= 510 && getTimeMin(endTime)< 705 && getTimeMin(endTime)> 510;
        //b.writeLog("result2结果为:" + result2);
        //3.外出开始时间小于等于8:30,外出时间小于13:00
        boolean result3 = getTimeMin(startTime) <= 510 && getTimeMin(endTime)<= 780 && getTimeMin(endTime)>= 705;
        //b.writeLog("result3结果为:" + result3);
        //4.外出开始时间小于等于8:30,外出时间小于17:15
        boolean result4 = getTimeMin(startTime) <= 510 && getTimeMin(endTime)< 1035 && getTimeMin(endTime)> 780;
        //b.writeLog("result4结果为:" + result4);
        //5.外出开始时间小于等于8:30,外出时间大于等于17:15
        boolean result5 = getTimeMin(startTime) <= 510 && getTimeMin(endTime)>= 1035;
        //b.writeLog("result5结果为:" + result5);
        //6.外出开始时间小于11:45,外出结束时间小于11:45
        boolean result6 = getTimeMin(startTime) > 510 && getTimeMin(startTime) < 705 && getTimeMin(endTime)< 705 && getTimeMin(endTime)> 510;
        //b.writeLog("result6结果为:" + result6);
        //7.外出开始时间小于11:45,外出结束时间小于13:00
        boolean result7 = getTimeMin(startTime) > 510 && getTimeMin(startTime) < 705 && getTimeMin(endTime)< 780 && getTimeMin(endTime)>= 705;
        //b.writeLog("result7结果为:" + result7);
        //8.外出开始时间小于11:45,外出结束时间小于17:15
        boolean result8 = getTimeMin(startTime) > 510 && getTimeMin(startTime) < 705 && getTimeMin(endTime)< 1035 && getTimeMin(endTime)>= 780;
        //b.writeLog("result8结果为:" + result8);
        //9.外出开始时间小于11:45,外出结束时间大于等于17:15
        boolean result9 = getTimeMin(startTime) > 510 && getTimeMin(startTime) < 705 && getTimeMin(endTime)>= 1035;
        //b.writeLog("result9结果为:" + result9);
        //11.外出开始时间小于13:00,外出结束时间小于17:15
        boolean result11 = getTimeMin(startTime) >= 705 && getTimeMin(startTime) <= 780 && getTimeMin(endTime)< 1035 && getTimeMin(endTime)>= 780;
        //b.writeLog("result11结果为:" + result11);
        //12.外出开始时间小于13:00,外出结束时间大于等于17:15
        boolean result12 = getTimeMin(startTime) >= 705 && getTimeMin(startTime) <= 780 && getTimeMin(endTime)>= 1035;
        //b.writeLog("result12结果为:" + result12);
        //13.外出开始时间小于17:15,外出结束时间小于17:15
        boolean result13 = getTimeMin(startTime) > 780 && getTimeMin(startTime) < 1035 && getTimeMin(endTime)< 1035 && getTimeMin(endTime)> 780;
        //14.外出开始时间小于17:15,外出结束时间大于等于17:15
        boolean result14 = getTimeMin(startTime) > 780 && getTimeMin(startTime) < 1035 && getTimeMin(endTime)>= 1035;
        //b.writeLog("result14结果为:" + result14);

        //定义签到时间
        List<String> oldSignInList = new ArrayList<String>();
        //定义签退数据
        List<String> oldSignOutList = new ArrayList<String>();
        if(result2||result3||result4||result5||result7||result9||result11||result12||result14){
            if (result2) {
                //请假开始时间小于等于8:30,请假结束时间小于11:45
                //当天有打卡记录
                if(isNumber>0) {
                    for (String signTime : gooutStartDate) {
                        //取出请假当天上午签到数据
                        if (signTime.endsWith("1") && getTimeMin(signTime) <720) {
                            oldSignInList.add(signTime);
                        } else {
                            leaveList.add(signTime);
                        }
                    }
                    //有打卡时间则取第一次签到时间 否则赋值为空
                    String signInTime = oldSignInList.size() > 0 ? oldSignInList.get(0) : "";
                    //上午签到时间与请假结束时间比较 签到时间<=请假结束时间 将标准数据补上 否则默认为原打卡数据
                    if (signInTime.compareTo(endTime) <= 0 && !signInTime.equals("")) {
                        endTime = endTime.substring(0, 9) + "2";
                    } else {
                        leaveList.add(signInTime);
                    }
                }
            }
            if (result3) {
                //请假开始时间小于等于8:30,外出时间小于13:00
                startTime = "08:30:00:" + leaveinFlag;
                endTime = "11:45:00:"+leaveoutFlag;
                if(isNumber>0){
                    for(String time:gooutStartDate){
                        if(getTimeMin(time)>=720){
                            leaveList.add(time);
                        }
                    }
                }
            }
            if (result4) {
                //请假开始时间小于等于8:30,外出时间小于17:15
                if(isNumber>0){
                    for (String signTime : gooutStartDate) {
                        int signForHour = Integer.parseInt(signTime.substring(0, 2));//打卡时间对应的小时数
                        if (signTime.endsWith("1") && signForHour >= 12) {
                            oldSignInList.add(signTime);
                        }else if(signTime.endsWith("2") && signForHour >= 12){
                            leaveList.add(signTime);
                        }
                    }
                    String signInTime=oldSignInList.size() > 0?oldSignInList.get(0):"";//有打卡时间则取第一次签到时间 否则赋值为空
                    //下午签到时间与请假结束时间比较 签到时间<=请假结束时间 将标准数据补上 否则默认为原打卡数据
                    if (signInTime.compareTo(endTime) <= 0&& !signInTime.equals("")) {
                        endTime=endTime.substring(0,9)+"2";
                        leaveList.add("11:45:00:"+leaveoutFlag);
                        leaveList.add("13:00:00:"+leaveinFlag);
                    }else{
                        leaveList.add(signInTime);
                        leaveList.add("11:45:00:"+leaveoutFlag);
                        leaveList.add("13:00:00:"+leaveinFlag);
                    }
                }else{
                    //当天无打卡记录
                    leaveList.add("11:45:00:"+leaveoutFlag);
                    leaveList.add("13:00:00:"+leaveinFlag);
                }
            }
            if (result5) {
                //外出开始时间小于等于8:30,外出时间大于等于17:15
                startTime = "08:30:00:"+leaveinFlag;
                endTime = "17:15:00:"+leaveoutFlag;
                leaveList.add("11:45:00:"+leaveoutFlag);
                leaveList.add("13:00:00:"+leaveinFlag);
            }
            if (result7) {
                if(isNumber>0){
                    //请假开始时间小于11:45,请假结束时间小于13:00
                    for (String signTime : gooutStartDate) {
                        int signForHour = Integer.parseInt(signTime.substring(0, 2));//打卡时间对应的小时数
                        if (signTime.endsWith("2") && signForHour < 12) {
                            oldSignOutList.add(signTime);
                        }else{
                            leaveList.add(signTime);
                        }
                    }
                    String signOutTime = oldSignOutList.size() > 0?oldSignOutList.get(oldSignOutList.size() - 1):"";//取上午最后一条签退数据
                    endTime=(endTimeForHours*60+endTimeForMinutes)>705?("11:45:00:"+leaveoutFlag):endTime;
                    //上午签退时间与请假开始时间比较 签退时间>=请假开始时间 将标准数据补上 否则默认为原打卡数据
                    if (signOutTime.compareTo(startTime) >= 0&& !signOutTime.equals("")) {
                        startTime=startTime.substring(0,9)+"1";
                    }else{
                        leaveList.add(signOutTime);
                    }
                }else{
                    endTime=(endTimeForHours*60+endTimeForMinutes)>705?("11:45:00:"+leaveoutFlag):endTime;
                }
            }
            if (result9) {
                if(isNumber>0){
                    //外出开始时间小于11:45,外出结束时间大于等于17:15
                    //上午签退时间与开始时间比较
                    for (String signTime : gooutStartDate) {
                        int signForHour = Integer.parseInt(signTime.substring(0, 2));//打卡时间对应的小时数
                        if (signTime.endsWith("2") && signForHour < 12) {
                            oldSignOutList.add(signTime);
                        }else if (signTime.endsWith("1") && signForHour < 12) {
                            leaveList.add(signTime);
                        }
                    }
                    String signOutTime = oldSignOutList.size() > 0?oldSignOutList.get(oldSignOutList.size() - 1):"";//取最后一次上午签退时间
                    //上午签退时间与请假开始时间比较 签退时间>=请假开始时间 将标准数据补上 否则默认为原打卡数据
                    //b.writeLog("上午签退时间:"+signOutTime+"请假开始时间:"+startTime+";两者比较:"+signOutTime.compareTo(startTime));
                    if (signOutTime.compareTo(startTime) >= 0&& !signOutTime.equals("")) {
                        startTime=startTime.substring(0,9)+"1";
                        leaveList.add("11:45:00:"+leaveoutFlag);
                        leaveList.add("13:00:00:"+leaveinFlag);
                    }else{
                        leaveList.add(signOutTime);
                        leaveList.add("11:45:00:"+leaveoutFlag);
                        leaveList.add("13:00:00:"+leaveinFlag);
                    }
                }else{
                    leaveList.add("11:45:00:"+leaveoutFlag);
                    leaveList.add("13:00:00:"+leaveinFlag);
                }
            }
            if (result11) {
                startTime="13:00:00:3";
                if(isNumber>0){
                    //开始时间小于13:00,结束时间小于17:15
                    for (String signTime : gooutStartDate) {
                        int signForHour = Integer.parseInt(signTime.substring(0, 2));//打卡时间对应的小时数
                        if (signTime.endsWith("1") && signForHour >= 12) {
                            oldSignInList.add(signTime);
                        } else if (signTime.endsWith("2") && signForHour >= 12) {
                            leaveList.add(signTime);
                        }
                    }
                    String signInTime = oldSignInList.size()>0?oldSignInList.get(0):"";//取第一次下午签到时间
                    //下午签到时间与请假结束时间比较 签到时间<=请假结束时间 将标准数据补上 否则默认为原打卡数据
                    if (signInTime.compareTo(endTime) <= 0&& !signInTime.equals("")) {
                        endTime=endTime.substring(0,9)+"2";
                        leaveList.add(startTime);
                        leaveList.add(endTime);
                        value.put(outdate, leaveList);
                    }else{
                        leaveList.add(startTime);
                        leaveList.add(endTime);
                        leaveList.add(signInTime);
                        value.put(outdate, leaveList);
                    }
                }
            }
            if (result12) {
                if(isNumber>0){
                    for (String signTime : gooutStartDate) {
                        int signForHour = Integer.parseInt(signTime.substring(0, 2));//打卡时间对应的小时数
                        if (signForHour<12) {
                            leaveList.add(signTime);
                        }
                    }
                }
                startTime = "13:00:00:" + leaveinFlag;
                endTime = "17:15:00:" + leaveoutFlag;
            }
            if (result14) {
                endTime="17:15:00:"+leaveoutFlag;
                if(isNumber>0){
                    //外出开始时间小于17:15,外出结束时间大于等于17:15
                    for (String signTime : gooutStartDate) {
                        int signForHour = Integer.parseInt(signTime.substring(0, 2));//打卡时间对应的小时数
                        int signForMin = Integer.parseInt(signTime.substring(3, 5));//打卡时间对应的分钟数
                        if ((signTime.endsWith("2")||signTime.endsWith("4")||signTime.endsWith("6")) && signForHour >= 12 && (signForHour*60+signForMin)<=1035) {
                            oldSignOutList.add(signTime);
                        }else{
                            leaveList.add(signTime);
                        }
                    }
                    String signOutTime = oldSignOutList.size() > 0?oldSignOutList.get(oldSignOutList.size() - 1):"";//取最后一次下午签退时间
                    //下午签退时间与请假开始时间比较 签退时间>=请假开始时间 将标准数据补上 否则默认为原打卡数据
                    if (signOutTime.compareTo(startTime) >= 0&& !signOutTime.equals("")) {
                        startTime=startTime.substring(0,9)+"1";
                    }else{
                        leaveList.add(signOutTime);
                    }
                }
            }
            leaveList.add(startTime);
            leaveList.add(endTime);
            value.put(outdate, attendanceUtil.removeNull(leaveList));
        }


        if(result6){
            //外出开始时间小于11:45,外出结束时间小于11:45
            if (value.containsKey(outdate)) {
                for (int i = 0; i < gooutStartDate.size(); i++) {
                    if(gooutStartDate.size()==1){
                        //当天只有一个打卡时间
                        if(gooutStartDate.get(0).compareTo(startTime)>=0&&gooutStartDate.get(0).compareTo(endTime)<=0){
                            gooutStartDate.remove(0);
                            break;
                        }
                        gooutStartDate.add(startTime);
                        gooutStartDate.add(endTime);
                    }else {
                        String time = gooutStartDate.get(i);
                        if (Integer.parseInt(time.substring(0, 2)) < 12 && time.endsWith("2")) {
                            //08:00:1   10:00:2  10:45:3  11:45:4
                            if (time.compareTo(startTime) <= 0) {
                                gooutStartDate.add(startTime);
                                gooutStartDate.add(endTime);
                            }
                        } else if (Integer.parseInt(time.substring(0, 2)) < 12 && time.endsWith("1")) {
                            //08:00:3   10:00:4  10:45:1  11:45:2
                            if (time.compareTo(endTime) >= 0) {
                                gooutStartDate.add(startTime);
                                gooutStartDate.add(endTime);
                            }
                        }
                    }
                }
            } else {
                //当天无打卡记录
                gooutStartDate.add(startTime);
                gooutStartDate.add(endTime);
            }
            value.put(outdate, gooutStartDate);
        }
         if (result8) {
            if(isNumber>0){
                //当天有打卡记录
                //请假开始时间小于11:45,请假结束时间小于17:15
                //上午签退时间与请假开始时间相比 下午签到时间与请假结束时间相比
                for (String signTime : gooutStartDate) {
                    int signForHour = Integer.parseInt(signTime.substring(0, 2));//打卡时间对应的小时数
                    if (signTime.endsWith("2") && signForHour < 12) {
                        oldSignOutList.add(signTime);
                    }else if (signTime.endsWith("1") && signForHour < 12) {
                        leaveList.add(signTime);
                    }
                    if (signTime.endsWith("1") && signForHour >= 12) {
                        oldSignInList.add(signTime);
                    }else if(signTime.endsWith("2") && signForHour >= 12) {
                        leaveList.add(signTime);
                    }
                }
                String signOutTime = oldSignOutList.size() > 0?oldSignOutList.get(oldSignOutList.size() - 1):"";//取最后一次上午签退时间
                String signInTime = oldSignInList.size()>0?oldSignInList.get(0):"";//取第一次下午签到时间

                //上午签退时间与请假开始时间比较 签退时间>=请假开始时间 下午签到时间与请假结束时间比较 签到时间<=请假结束时间 将标准数据补上 否则默认为原打卡数据
                if (signOutTime.compareTo(startTime) >= 0&& !signOutTime.equals("")) {
                    startTime=startTime.substring(0,9)+"1";
                    leaveList.add(startTime);
                    leaveList.add("11:45:00:"+leaveoutFlag);
                    leaveList.add("13:00:00:"+leaveinFlag);
                }else{
                    leaveList.add(startTime);
                    leaveList.add(signOutTime);
                    leaveList.add("11:45:00:"+leaveoutFlag);
                    leaveList.add("13:00:00:"+leaveinFlag);
                }
                //b.writeLog("请假开始时间与签退相比:"+gooutStartDate);
                if(signInTime.compareTo(endTime) <= 0&& !signInTime.equals("")){
                    //b.writeLog("endTime:--------"+endTime);
                    endTime=endTime.substring(0,9)+"2";
                    leaveList.add(endTime);
                }else{
                    leaveList.add(signInTime);
                    leaveList.add(endTime);
                }

            }else {
                leaveList.add(startTime);
                leaveList.add(endTime);
                leaveList.add("11:45:00:"+leaveoutFlag);
                leaveList.add("13:00:00:"+leaveinFlag);
            }
             value.put(outdate,attendanceUtil.removeNull(leaveList));
         }
         if (result13) {
            if (isNumber > 0) {
                //当天有打卡集合
                if(gooutStartDate.size()==1){
                    gooutStartDate.add(startTime);
                    gooutStartDate.add(endTime);
                }else {
                    //当天有两个及以上打卡记录
                    for (String signTime : gooutStartDate) {
                        int signForHour = Integer.parseInt(signTime.substring(0, 2));//打卡时间对应的小时数
                        int signForMin = Integer.parseInt(signTime.substring(3, 5));//打卡时间对应的分钟数
                        if ((signTime.endsWith("2")||signTime.endsWith("4")||signTime.endsWith("6")) && signForHour >= 12 && (signForHour*60+signForMin)<=1035) {
                            oldSignOutList.add(signTime);
                        }
                        if ((signTime.endsWith("1")||signTime.endsWith("3")||signTime.endsWith("5")) && signForHour >= 12 && (signForHour*60+signForMin)<=1035) {
                            oldSignInList.add(signTime);
                        }
                    }
                    String signOutTime = oldSignOutList.size() > 0 ? oldSignOutList.get(oldSignOutList.size() - 1) : "";//取最后一次下午签退时间
                    String signInTime = oldSignInList.size() > 0 ? oldSignInList.get(oldSignOutList.size() - 1) : "";//取最后一次下午签退时间
                    //下午签退时间与请假开始时间比较 签退时间>=请假开始时间 将标准数据补上 否则默认为原打卡数据
                    if (signOutTime.compareTo(startTime) >= 0 && !signOutTime.equals("")) {
                        startTime = startTime.substring(0, 9) + "1";
                        gooutStartDate.add(startTime);
                    } else if(signInTime.compareTo(endTime) <= 0 && !signInTime.equals("")){
                        endTime = endTime.substring(0, 9) + "2";
                        gooutStartDate.add(endTime);
                    } else {
                        gooutStartDate.add(startTime);
                        gooutStartDate.add(endTime);
                    }
                }
                value.put(outdate, gooutStartDate);
            } else {
                gooutStartDate.add(startTime);
                gooutStartDate.add(endTime);
                value.put(outdate, gooutStartDate);
            }
        }
    }
    public void changeSaturdayTime(Map<String, List<String>> value, String startTime, String endTime, String outdate, String leaveinFlag, String leaveoutFlag) {
        List<String> gooutStartDate=new LinkedList<String>();
        //定义一个空集合处理请假数据
        List<String> leaveList=new LinkedList<String>();
        //如果打卡集合中包含当天打卡记录 则获取当天打卡数据
        if(value.containsKey(outdate)){
            gooutStartDate = value.get(outdate);
            Collections.sort(gooutStartDate);
        }
        int isNumber=gooutStartDate.size();//集合是否为空

        int endTimeForHours = Integer.parseInt(endTime.split(":")[0]);
        int endTimeForMinutes = Integer.parseInt(endTime.split(":")[1]);

        //修改zcc 2020.06.20 ---start---
        startTime=startTime+":00:"+leaveinFlag;//将请假开始时间变成打卡签到时间
        startTime=startTime.compareTo("08:30:00:"+leaveinFlag)<=0?("08:30:00:"+leaveinFlag):startTime;
        endTime=endTime+":00:"+leaveoutFlag;//将请假结束时间变成打卡签退时间
        endTime=endTime.compareTo("16:15:00:"+leaveoutFlag)>=0?("16:15:00:"+leaveoutFlag):endTime;

        //前提（结束时间一定大于开始时间）
        //2.外出开始时间小于等于8:30,外出结束时间小于11:45
        boolean result2 = getTimeMin(startTime) <= 510 && getTimeMin(endTime)< 705 && getTimeMin(endTime)> 510;
        //b.writeLog("result2结果为:" + result2);
        //3.外出开始时间小于等于8:30,外出时间小于13:00
        boolean result3 = getTimeMin(startTime) <= 510 && getTimeMin(endTime)<= 780 && getTimeMin(endTime)>= 705;
        //b.writeLog("result3结果为:" + result3);
        //4.外出开始时间小于等于8:30,外出时间小于16:15
        boolean result4 = getTimeMin(startTime) <= 510 && getTimeMin(endTime)< 975 && getTimeMin(endTime)> 780;
        //b.writeLog("result4结果为:" + result4);
        //5.外出开始时间小于等于8:30,外出时间大于等于16:15
        boolean result5 = getTimeMin(startTime) <= 510 && getTimeMin(endTime)>= 975;
        //b.writeLog("result5结果为:" + result5);
        //6.外出开始时间小于11:45,外出结束时间小于11:45
        boolean result6 = getTimeMin(startTime) > 510 && getTimeMin(startTime) < 705 && getTimeMin(endTime)< 705 && getTimeMin(endTime)> 510;
        //b.writeLog("result6结果为:" + result6);
        //7.外出开始时间小于11:45,外出结束时间小于13:00
        boolean result7 = getTimeMin(startTime) > 510 && getTimeMin(startTime) < 705 && getTimeMin(endTime)< 780 && getTimeMin(endTime)>= 705;
        //b.writeLog("result7结果为:" + result7);
        //8.外出开始时间小于11:45,外出结束时间小于16:15
        boolean result8 = getTimeMin(startTime) > 510 && getTimeMin(startTime) < 705 && getTimeMin(endTime)< 975 && getTimeMin(endTime)>= 780;
        //b.writeLog("result8结果为:" + result8);
        //9.外出开始时间小于11:45,外出结束时间大于等于16:15
        boolean result9 = getTimeMin(startTime) > 510 && getTimeMin(startTime) < 705 && getTimeMin(endTime)>= 975;
        //b.writeLog("result9结果为:" + result9);
        //11.外出开始时间小于13:00,外出结束时间小于16:15
        boolean result11 = getTimeMin(startTime) >= 705 && getTimeMin(startTime) <= 780 && getTimeMin(endTime)< 975 && getTimeMin(endTime)>= 780;
        //b.writeLog("result11结果为:" + result11);
        //12.外出开始时间小于13:00,外出结束时间大于等于16:15
        boolean result12 = getTimeMin(startTime) >= 705 && getTimeMin(startTime) <= 780 && getTimeMin(endTime)>= 975;
        //b.writeLog("result12结果为:" + result12);
        //13.外出开始时间小于16:15,外出结束时间小于16:15
        boolean result13 = getTimeMin(startTime) > 780 && getTimeMin(startTime) < 975 && getTimeMin(endTime)< 975 && getTimeMin(endTime)> 780;
        //14.外出开始时间小于16:15,外出结束时间大于等于16:15
        boolean result14 = getTimeMin(startTime) > 780 && getTimeMin(startTime) < 975 && getTimeMin(endTime)>= 975;
        //b.writeLog("result14结果为:" + result14);

        //定义签到时间
        List<String> oldSignInList = new ArrayList<String>();
        //定义签退数据
        List<String> oldSignOutList = new ArrayList<String>();
        if(result2||result3||result4||result5||result7||result9||result11||result12||result14){
            if (result2) {
                //请假开始时间小于等于8:30,请假结束时间小于11:45
                //当天有打卡记录
                if(isNumber>0) {
                    for (String signTime : gooutStartDate) {
                        //取出请假当天上午签到数据
                        if (signTime.endsWith("1") && getTimeMin(signTime) <720) {
                            oldSignInList.add(signTime);
                        } else {
                            leaveList.add(signTime);
                        }
                    }
                    //有打卡时间则取第一次签到时间 否则赋值为空
                    String signInTime = oldSignInList.size() > 0 ? oldSignInList.get(0) : "";
                    //上午签到时间与请假结束时间比较 签到时间<=请假结束时间 将标准数据补上 否则默认为原打卡数据
                    if (signInTime.compareTo(endTime) <= 0 && !signInTime.equals("")) {
                        endTime = endTime.substring(0, 9) + "2";
                    } else {
                        leaveList.add(signInTime);
                    }
                }
            }
            if (result3) {
                //请假开始时间小于等于8:30,外出时间小于13:00
                startTime = "08:30:00:" + leaveinFlag;
                endTime = "11:45:00:"+leaveoutFlag;
                if(isNumber>0){
                    for(String time:gooutStartDate){
                        if(getTimeMin(time)>=780){
                            leaveList.add(time);
                        }
                    }
                }
            }
            if (result4) {
                //请假开始时间小于等于8:30,外出时间小于16:15
                if(isNumber>0){
                    for (String signTime : gooutStartDate) {
                        int signForHour = Integer.parseInt(signTime.substring(0, 2));//打卡时间对应的小时数
                        if (signTime.endsWith("1") && signForHour >= 12) {
                            oldSignInList.add(signTime);
                        }else if(signTime.endsWith("2") && signForHour >= 12){
                            leaveList.add(signTime);
                        }
                    }
                    String signInTime=oldSignInList.size() > 0?oldSignInList.get(0):"";//有打卡时间则取第一次签到时间 否则赋值为空
                    //下午签到时间与请假结束时间比较 签到时间<=请假结束时间 将标准数据补上 否则默认为原打卡数据
                    if (signInTime.compareTo(endTime) <= 0&& !signInTime.equals("")) {
                        endTime=endTime.substring(0,9)+"2";
                        leaveList.add("11:45:00:"+leaveoutFlag);
                        leaveList.add("13:00:00:"+leaveinFlag);
                    }else{
                        leaveList.add(signInTime);
                        leaveList.add("11:45:00:"+leaveoutFlag);
                        leaveList.add("13:00:00:"+leaveinFlag);
                    }
                }else{
                    //当天无打卡记录
                    leaveList.add("11:45:00:"+leaveoutFlag);
                    leaveList.add("13:00:00:"+leaveinFlag);
                }
            }
            if (result5) {
                //外出开始时间小于等于8:30,外出时间大于等于16:15
                startTime = "08:30:00:"+leaveinFlag;
                endTime = "16:15:00:"+leaveoutFlag;
                leaveList.add("11:45:00:"+leaveoutFlag);
                leaveList.add("13:00:00:"+leaveinFlag);
            }
            if (result7) {
                if(isNumber>0){
                    //请假开始时间小于11:45,请假结束时间小于13:00
                    for (String signTime : gooutStartDate) {
                        int signForHour = Integer.parseInt(signTime.substring(0, 2));//打卡时间对应的小时数
                        if (signTime.endsWith("2") && signForHour < 12) {
                            oldSignOutList.add(signTime);
                        }else{
                            leaveList.add(signTime);
                        }
                    }
                    String signOutTime = oldSignOutList.size() > 0?oldSignOutList.get(oldSignOutList.size() - 1):"";//取上午最后一条签退数据
                    endTime=(endTimeForHours*60+endTimeForMinutes)>705?("11:45:00:"+leaveoutFlag):endTime;
                    //上午签退时间与请假开始时间比较 签退时间>=请假开始时间 将标准数据补上 否则默认为原打卡数据
                    if (signOutTime.compareTo(startTime) >= 0&& !signOutTime.equals("")) {
                        startTime=startTime.substring(0,9)+"1";
                    }else{
                        leaveList.add(signOutTime);
                    }
                }else{
                    endTime=(endTimeForHours*60+endTimeForMinutes)>705?("11:45:00:"+leaveoutFlag):endTime;
                }
            }
            if (result9) {
                if(isNumber>0){
                    //外出开始时间小于11:45,外出结束时间大于等于16:15
                    //上午签退时间与开始时间比较
                    for (String signTime : gooutStartDate) {
                        int signForHour = Integer.parseInt(signTime.substring(0, 2));//打卡时间对应的小时数
                        if (signTime.endsWith("2") && signForHour < 12) {
                            oldSignOutList.add(signTime);
                        }else if (signTime.endsWith("1") && signForHour < 12) {
                            leaveList.add(signTime);
                        }
                    }
                    String signOutTime = oldSignOutList.size() > 0?oldSignOutList.get(oldSignOutList.size() - 1):"";//取最后一次上午签退时间
                    //上午签退时间与请假开始时间比较 签退时间>=请假开始时间 将标准数据补上 否则默认为原打卡数据
                    //b.writeLog("上午签退时间:"+signOutTime+"请假开始时间:"+startTime+";两者比较:"+signOutTime.compareTo(startTime));
                    if (signOutTime.compareTo(startTime) >= 0&& !signOutTime.equals("")) {
                        startTime=startTime.substring(0,9)+"1";
                        leaveList.add("11:45:00:"+leaveoutFlag);
                        leaveList.add("13:00:00:"+leaveinFlag);
                    }else{
                        leaveList.add(signOutTime);
                        leaveList.add("11:45:00:"+leaveoutFlag);
                        leaveList.add("13:00:00:"+leaveinFlag);
                    }
                }else{
                    leaveList.add("11:45:00:"+leaveoutFlag);
                    leaveList.add("13:00:00:"+leaveinFlag);
                }
            }
            if (result11) {
                startTime="13:00:00:3";
                if(isNumber>0){
                    //开始时间小于13:00,结束时间小于16:15
                    for (String signTime : gooutStartDate) {
                        int signForHour = Integer.parseInt(signTime.substring(0, 2));//打卡时间对应的小时数
                        if (signTime.endsWith("1") && signForHour >= 12) {
                            oldSignInList.add(signTime);
                        } else if (signTime.endsWith("2") && signForHour >= 12) {
                            leaveList.add(signTime);
                        }
                    }
                    String signInTime = oldSignInList.size()>0?oldSignInList.get(0):"";//取第一次下午签到时间
                    //下午签到时间与请假结束时间比较 签到时间<=请假结束时间 将标准数据补上 否则默认为原打卡数据
                    if (signInTime.compareTo(endTime) <= 0&& !signInTime.equals("")) {
                        endTime=endTime.substring(0,9)+"2";
                        leaveList.add(startTime);
                        leaveList.add(endTime);
                        value.put(outdate, leaveList);
                    }else{
                        leaveList.add(startTime);
                        leaveList.add(endTime);
                        leaveList.add(signInTime);
                        value.put(outdate, leaveList);
                    }
                }
            }
            if (result12) {
                if(isNumber>0){
                    for (String signTime : gooutStartDate) {
                        int signForHour = Integer.parseInt(signTime.substring(0, 2));//打卡时间对应的小时数
                        if (signForHour<12) {
                            leaveList.add(signTime);
                        }
                    }
                }
                startTime = "13:00:00:" + leaveinFlag;
                endTime = "16:15:00:" + leaveoutFlag;
            }
            if (result14) {
                endTime="16:15:00:"+leaveoutFlag;
                if(isNumber>0){
                    //外出开始时间小于16:15,外出结束时间大于等于16:15
                    for (String signTime : gooutStartDate) {
                        int signForHour = Integer.parseInt(signTime.substring(0, 2));//打卡时间对应的小时数
                        int signForMin = Integer.parseInt(signTime.substring(3, 5));//打卡时间对应的分钟数
                        if ((signTime.endsWith("2")||signTime.endsWith("4")||signTime.endsWith("6")) && signForHour >= 12 && (signForHour*60+signForMin)<=975) {
                            oldSignOutList.add(signTime);
                        }else{
                            leaveList.add(signTime);
                        }
                    }
                    String signOutTime = oldSignOutList.size() > 0?oldSignOutList.get(oldSignOutList.size() - 1):"";//取最后一次下午签退时间
                    //下午签退时间与请假开始时间比较 签退时间>=请假开始时间 将标准数据补上 否则默认为原打卡数据
                    if (signOutTime.compareTo(startTime) >= 0&& !signOutTime.equals("")) {
                        startTime=startTime.substring(0,9)+"1";
                    }else{
                        leaveList.add(signOutTime);
                    }
                }
            }
            leaveList.add(startTime);
            leaveList.add(endTime);
            value.put(outdate, attendanceUtil.removeNull(leaveList));
        }


        if(result6){
            //外出开始时间小于11:45,外出结束时间小于11:45
            if (value.containsKey(outdate)) {
                for (int i = 0; i < gooutStartDate.size(); i++) {
                    if(gooutStartDate.size()==1){
                        //当天只有一个打卡时间
                        if(gooutStartDate.get(0).compareTo(startTime)>=0&&gooutStartDate.get(0).compareTo(endTime)<=0){
                            gooutStartDate.remove(0);
                            break;
                        }
                        gooutStartDate.add(startTime);
                        gooutStartDate.add(endTime);
                    }else {
                        String time = gooutStartDate.get(i);
                        if (Integer.parseInt(time.substring(0, 2)) < 12 && time.endsWith("2")) {
                            //08:00:1   10:00:2  10:45:3  11:45:4
                            if (time.compareTo(startTime) <= 0) {
                                gooutStartDate.add(startTime);
                                gooutStartDate.add(endTime);
                            }
                        } else if (Integer.parseInt(time.substring(0, 2)) < 12 && time.endsWith("1")) {
                            //08:00:3   10:00:4  10:45:1  11:45:2
                            if (time.compareTo(endTime) >= 0) {
                                gooutStartDate.add(startTime);
                                gooutStartDate.add(endTime);
                            }
                        }
                    }
                }
            } else {
                //当天无打卡记录
                gooutStartDate.add(startTime);
                gooutStartDate.add(endTime);
            }
            value.put(outdate, gooutStartDate);
        }
        if (result8) {
            if(isNumber>0){
                //当天有打卡记录
                //请假开始时间小于11:45,请假结束时间小于16:15
                //上午签退时间与请假开始时间相比 下午签到时间与请假结束时间相比
                for (String signTime : gooutStartDate) {
                    int signForHour = Integer.parseInt(signTime.substring(0, 2));//打卡时间对应的小时数
                    if (signTime.endsWith("2") && signForHour < 12) {
                        oldSignOutList.add(signTime);
                    }else if (signTime.endsWith("1") && signForHour < 12) {
                        leaveList.add(signTime);
                    }
                    if (signTime.endsWith("1") && signForHour >= 12) {
                        oldSignInList.add(signTime);
                    }else if(signTime.endsWith("2") && signForHour >= 12) {
                        leaveList.add(signTime);
                    }
                }
                String signOutTime = oldSignOutList.size() > 0?oldSignOutList.get(oldSignOutList.size() - 1):"";//取最后一次上午签退时间
                String signInTime = oldSignInList.size()>0?oldSignInList.get(0):"";//取第一次下午签到时间

                //上午签退时间与请假开始时间比较 签退时间>=请假开始时间 下午签到时间与请假结束时间比较 签到时间<=请假结束时间 将标准数据补上 否则默认为原打卡数据
                if (signOutTime.compareTo(startTime) >= 0&& !signOutTime.equals("")) {
                    startTime=startTime.substring(0,9)+"1";
                    leaveList.add(startTime);
                    leaveList.add("11:45:00:"+leaveoutFlag);
                    leaveList.add("13:00:00:"+leaveinFlag);
                }else{
                    leaveList.add(startTime);
                    leaveList.add(signOutTime);
                    leaveList.add("11:45:00:"+leaveoutFlag);
                    leaveList.add("13:00:00:"+leaveinFlag);
                }
                //b.writeLog("请假开始时间与签退相比:"+gooutStartDate);
                if(signInTime.compareTo(endTime) <= 0&& !signInTime.equals("")){
                    //b.writeLog("endTime:--------"+endTime);
                    endTime=endTime.substring(0,9)+"2";
                    leaveList.add(endTime);
                }else{
                    leaveList.add(signInTime);
                    leaveList.add(endTime);
                }
            }else {
                leaveList.add(startTime);
                leaveList.add(endTime);
                leaveList.add("11:45:00:"+leaveoutFlag);
                leaveList.add("13:00:00:"+leaveinFlag);
            }
            value.put(outdate,attendanceUtil.removeNull(leaveList));
        }
        if (result13) {
            if (isNumber > 0) {
                //当天有打卡集合
                if(gooutStartDate.size()==1){
                    gooutStartDate.add(startTime);
                    gooutStartDate.add(endTime);
                }else {
                    //当天有两个及以上打卡记录
                    for (String signTime : gooutStartDate) {
                        int signForHour = Integer.parseInt(signTime.substring(0, 2));//打卡时间对应的小时数
                        int signForMin = Integer.parseInt(signTime.substring(3, 5));//打卡时间对应的分钟数
                        if ((signTime.endsWith("2")||signTime.endsWith("4")||signTime.endsWith("6")) && signForHour >= 12 && (signForHour*60+signForMin)<=975) {
                            oldSignOutList.add(signTime);
                        }
                        if ((signTime.endsWith("1")||signTime.endsWith("3")||signTime.endsWith("5")) && signForHour >= 12 && (signForHour*60+signForMin)<=975) {
                            oldSignInList.add(signTime);
                        }
                    }
                    String signOutTime = oldSignOutList.size() > 0 ? oldSignOutList.get(oldSignOutList.size() - 1) : "";//取最后一次下午签退时间
                    String signInTime = oldSignInList.size() > 0 ? oldSignInList.get(oldSignOutList.size() - 1) : "";//取最后一次下午签退时间
                    //下午签退时间与请假开始时间比较 签退时间>=请假开始时间 将标准数据补上 否则默认为原打卡数据
                    if (signOutTime.compareTo(startTime) >= 0 && !signOutTime.equals("")) {
                        startTime = startTime.substring(0, 9) + "1";
                        gooutStartDate.add(startTime);
                    } else if(signInTime.compareTo(endTime) <= 0 && !signInTime.equals("")){
                        endTime = endTime.substring(0, 9) + "2";
                        gooutStartDate.add(endTime);
                    } else {
                        gooutStartDate.add(startTime);
                        gooutStartDate.add(endTime);
                    }
                }
                value.put(outdate, gooutStartDate);
            } else {
                gooutStartDate.add(startTime);
                gooutStartDate.add(endTime);
                value.put(outdate, gooutStartDate);
            }
        }
    }

    public  int getId(String getCompanyIdSql){
        RecordSet recordSet = new RecordSet();
        recordSet.execute(getCompanyIdSql);
        recordSet.next();
        return recordSet.getInt(1);
    }
    public  int getTimeMin(String curTime) {
        return Integer.parseInt(curTime.split(":")[0])*60+Integer.parseInt(curTime.split(":")[1]);
    }

}