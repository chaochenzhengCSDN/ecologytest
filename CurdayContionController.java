package weaver.iiot.grouptow.common;

import com.weaver.general.Util;
import weaver.conn.RecordSet;
import weaver.general.BaseBean;
import weaver.iiot.grouptow.common.entity.AttendanceOption;
import weaver.iiot.grouptow.common.entity.CurdayContion;
import weaver.iiot.grouptow.util.AttendanceUtil;

import java.text.DecimalFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.*;


public class CurdayContionController {
    DecimalFormat df11 = new DecimalFormat("0.00");//设置保留位数

    FinalTimeListController finalTimeListController = new FinalTimeListController();

    AttendanceUtil attendanceUtil = new AttendanceUtil();

    public List<CurdayContion> getCurdayContions(Map<String,List<String>> map1, List<String> curdateList, List<String> saturdayList, BaseBean b,String id,String likeDate) {
        List<String> curdateList1 = new ArrayList<String>();//用于接收当前日期存在打卡记录的集合
        List<String> saturdayList1 = new ArrayList<String>();//用于接收当前存在打卡记录的集合
        List<CurdayContion> curdayContionList = new LinkedList<CurdayContion>();
        AttendanceUtil attendanceUtil = new AttendanceUtil();
        List<AttendanceOption> attendanceOptionList = getAttendanceCondition(id,likeDate);
        for (String key3 : map1.keySet()) {
            CurdayContion curdayContion = new CurdayContion();
            Double countHours = 0.00;
            Double lateTime = 0.00;
            Double earlyTime = 0.00;
            Double actualWorkingHours = 0.00;
            for(AttendanceOption attendanceOption:attendanceOptionList){
                if(attendanceOption.getCurDate().equals(key3)&&attendanceOption.getFrequency()==4){
                    List<String> finalTimeList = map1.get(key3);
                    List<String> morningList1 = new LinkedList<String>();
                    List<String> afternoonList1 = new LinkedList<String>();
                    for (String time5 : finalTimeList) {
                        if (getTimeMin(time5) < getTimeMin(attendanceOption.getMorningendtime1())) {
                            morningList1.add(time5);
                            Collections.sort(morningList1);
                        } else {
                            afternoonList1.add(time5);
                            Collections.sort(afternoonList1);
                        }
                    }

                    //b.writeLog("当天日期:"+key3+"<---->当天上午打卡情况:"+morningList1+"<---->当天打卡大小："+morningList1.size());

                    //计算上午打卡情况 将不满足条件的打卡情况去除
                    for (String time6 : morningList1) {
                        if (time6.endsWith("1") && (time6.compareTo(attendanceOption.getMorningendtime()+":1") > 0)) {
                            morningList1.remove(time6);
                            break;
                        }
                    }

                    /*
                     *
                     * 计算带请假的迟到早退旷工小时数(周一-----周五上午)
                     *
                     * */
                    if (morningList1.size() <= 1) {
                        //旷工小时数
                        countHours += Double.parseDouble(getDifferenceHours(attendanceOption.getStarttime(), attendanceOption.getMorningendtime()));
                    } else if (morningList1.size() == 2) {
                        //第一次打卡
                        String firstSign = morningList1.get(0);
                        //第一次打卡对应的分钟数
                        int firstSignForMin = getTimeMin(firstSign);
                        //第二次打卡
                        String secondSign = morningList1.get(1);
                        //第二次打卡对应的分钟数
                        int secondSignForMin = getTimeMin(secondSign);
                        if (firstSign.endsWith("1") && secondSign.endsWith("2")) {
                            //上午两次打卡数据 则计算迟到早退 08:30:00:1 09:30:00:2
                            lateTime += Math.max((firstSignForMin - getTimeMin(attendanceOption.getComparemorningin())), 0);
                            earlyTime += Math.max((getTimeMin(attendanceOption.getComparemorningout()) - secondSignForMin), 0);
                            List<String> LeaveList = getCurLeaveCondition(key3, id,attendanceOption);
                            b.writeLog("LeaveList：" + LeaveList);
                            //当天无请假记录或上午无请假时间
                            if (LeaveList.isEmpty() || LeaveList == null) {
                                actualWorkingHours += Double.parseDouble(getDifferenceHours(attendanceOption.getStarttime(), attendanceOption.getMorningendtime()));
                            } else {
                                Double relaxedHours = 0.0;
                                for (String leaveRecord : LeaveList) {
                                    String startTime = leaveRecord.split(",")[1];
                                    //如果请假开始时间大于11：45，则取11：45,如果开始时间小于08：30,则取08：30，其余情况则取默认值
                                    startTime = getTimeMin(startTime) > getTimeMin(attendanceOption.getMorningendtime()) ? attendanceOption.getMorningendtime() : getTimeMin(startTime) < getTimeMin(attendanceOption.getStarttime()) ? attendanceOption.getStarttime() : startTime;
                                    String endTime = leaveRecord.split(",")[2];
                                    //如果请假开始时间大于11：45，则取11：45,否则取默认值
                                    endTime = getTimeMin(endTime) > getTimeMin(attendanceOption.getMorningendtime()) ? attendanceOption.getMorningendtime() : getTimeMin(endTime) < getTimeMin(attendanceOption.getStarttime()) ? attendanceOption.getStarttime() : endTime;
                                    relaxedHours += Double.parseDouble(getDifferenceHours(startTime, endTime));
                                }
                                actualWorkingHours += Double.parseDouble(getDifferenceHours(attendanceOption.getStarttime(), attendanceOption.getMorningendtime())) - relaxedHours;
                            }
                        } else if (firstSign.endsWith("1") && !secondSign.endsWith("2")) {
                            //上午两次打卡记录， 08:30:00:1 11:00:00:4
                            lateTime += Math.max((firstSignForMin - getTimeMin(attendanceOption.getComparemorningin())), 0);
                            countHours += ((getTimeMin(attendanceOption.getMorningendtime()) - secondSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (getTimeMin(attendanceOption.getMorningendtime()) - secondSignForMin) / 60)) : 0;
                            List<String> leaveRecordList = getCurLeaveCondition(key3, id,attendanceOption);//获取当天打卡记录 计算出请假小时数
                            for (String leaveRecord : leaveRecordList) {
                                String startTime = leaveRecord.split(",")[1];//请假开始时间
                                startTime = startTime.compareTo(attendanceOption.getStarttime()) <= 0 ? attendanceOption.getStarttime() : startTime;
                                actualWorkingHours += Double.parseDouble(getDifferenceHours(attendanceOption.getStarttime(), startTime));//计算早上八点半到请假开始时间这段时间的实际工时
                            }
                        } else if (!firstSign.endsWith("1") && !secondSign.endsWith("2")) {
                            //上午两次请假数据 则计算旷工小数 08:30:00:3, 11:45:00:4
                            countHours += (((firstSignForMin - getTimeMin(attendanceOption.getStarttime())) > 0) ? Double.parseDouble(df11.format((float) (firstSignForMin - getTimeMin(attendanceOption.getStarttime())) / 60)) : 0) + (((getTimeMin(attendanceOption.getMorningendtime()) - secondSignForMin) >= 0) ? Double.valueOf(df11.format((float) (getTimeMin(attendanceOption.getMorningendtime()) - secondSignForMin) / 60)) : 0);
                        } else if (!firstSign.endsWith("1") && secondSign.endsWith("2")) {
                            //上午两次打卡记录， 08:30:00:3 11:30:00:2
                            countHours += ((firstSignForMin - getTimeMin(attendanceOption.getStarttime())) > 0) ? Double.parseDouble(df11.format((float) (firstSignForMin - getTimeMin(attendanceOption.getStarttime())) / 60)) : 0;
                            earlyTime += Math.max((getTimeMin(attendanceOption.getComparemorningout()) - secondSignForMin), 0);
                            List<String> leaveRecordList = getCurLeaveCondition(key3, id,attendanceOption);//获取当天打卡记录 计算出请假小时数
                            for (String leaveRecord : leaveRecordList) {
                                String endTime = leaveRecord.split(",")[2];//请假结束时间
                                endTime = endTime.compareTo(attendanceOption.getMorningendtime()) >= 0 ? attendanceOption.getMorningendtime() : endTime;
                                actualWorkingHours += Double.parseDouble(getDifferenceHours(endTime, attendanceOption.getMorningendtime()));//计算请假结束时间到11：45这段时间的实际工时
                            }
                        }
                    } else if (morningList1.size() == 3) {
                        //第一次打卡
                        String firstSign = morningList1.get(0);
                        //第一次打卡对应的分钟数
                        int firstSignForMin = getTimeMin(firstSign);
                        //第二次打卡
                        String secondSign = morningList1.get(1);
                        //第二次打卡对应的分钟数
                        int secondSignForMin = getTimeMin(secondSign);
                        //第三次打卡
                        String thirdSign = morningList1.get(2);
                        //第三次打卡对应的分钟数
                        int thirdSignForMin = getTimeMin(thirdSign);
                        if (firstSign.endsWith("1")) {
                            //上午三条记录 08：30：00：1  10：00：00：3 11：45：00：4
                            //上午第一次打卡时间前后计算旷工 第三次打卡时间计算旷工小时数
                            countHours += ((firstSignForMin - getTimeMin(attendanceOption.getStarttime())) > 0) ? Double.parseDouble(df11.format((float) (firstSignForMin - getTimeMin(attendanceOption.getStarttime())) / 60)) : 0;
                            countHours += ((secondSignForMin - firstSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (secondSignForMin - firstSignForMin) / 60)) : 0;
                            countHours += ((getTimeMin(attendanceOption.getMorningendtime()) - thirdSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (getTimeMin(attendanceOption.getMorningendtime()) - thirdSignForMin) / 60)) : 0;
                        } else if (thirdSign.endsWith("1")) {
                            //上午三条记录 08：30：00：3  10：00：00：4 11：00：00：1
                            //上午第一次打卡时间计算旷工小时数 第三次打卡时间前后计算旷工
                            countHours += ((firstSignForMin - getTimeMin(attendanceOption.getStarttime())) > 0) ? Double.parseDouble(df11.format((float) (firstSignForMin - getTimeMin(attendanceOption.getStarttime())) / 60)) : 0;
                            countHours += ((thirdSignForMin - secondSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (thirdSignForMin - secondSignForMin) / 60)) : 0;
                            countHours += ((getTimeMin(attendanceOption.getMorningendtime()) - thirdSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (getTimeMin(attendanceOption.getMorningendtime()) - thirdSignForMin) / 60)) : 0;
                        }
                    } else if (morningList1.size() == 4) {
                        //第一次打卡
                        String firstSign = morningList1.get(0);
                        //第一次打卡对应的分钟数
                        int firstSignForMin = getTimeMin(firstSign);
                        //第二次打卡
                        String secondSign = morningList1.get(1);
                        //第二次打卡对应的分钟数
                        int secondSignForMin = getTimeMin(secondSign);
                        //第三次打卡
                        String thirdSign = morningList1.get(2);
                        //第三次打卡对应的分钟数
                        int thirdSignForMin = getTimeMin(thirdSign);
                        //第四次打卡
                        String forthSign = morningList1.get(3);
                        //第四次打卡对应的分钟数
                        int forthSignForMin = getTimeMin(forthSign);
                        if (firstSign.endsWith("1")) {
                            //08：30：00：1 09:30:00:2 10：00：00：3 11：00：00：4
                            lateTime += Math.max((firstSignForMin - getTimeMin(attendanceOption.getComparemorningin())), 0);
                            earlyTime += Math.max((thirdSignForMin - secondSignForMin), 0);
                            countHours += ((getTimeMin(attendanceOption.getMorningendtime()) - forthSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (getTimeMin(attendanceOption.getMorningendtime()) - forthSignForMin) / 60)) : 0;
                            actualWorkingHours += Double.parseDouble(getDifferenceHours(attendanceOption.getStarttime(), thirdSign));//计算早上八点半到请假开始时间这段时间的实际工时
                        } else if (thirdSign.endsWith("1")) {
                            //上午四条记录 08：40：00：3 09:30:00:4 10：00：00：1 11：00：00：2
                            countHours += ((firstSignForMin - getTimeMin(attendanceOption.getStarttime())) > 0) ? Double.parseDouble(df11.format((float) (firstSignForMin - getTimeMin(attendanceOption.getStarttime())) / 60)) : 0;
                            lateTime += Math.max((thirdSignForMin - secondSignForMin), 0);
                            earlyTime += Math.max((getTimeMin(attendanceOption.getComparemorningout()) - forthSignForMin), 0);
                            actualWorkingHours += Double.parseDouble(getDifferenceHours(secondSign, attendanceOption.getMorningendtime()));//计算请假结束时间到11：45这段时间的实际工时
                        }
                    }
                    b.writeLog("当天日期:" + key3 + ";当天迟到分钟数:" + lateTime + ";当天早退分钟数:" + earlyTime + ";当天上午旷工小时数:" + countHours + ";当天上午实际工时：" + actualWorkingHours);
                    //b.writeLog("当天日期:"+key3+"<---->当天下午打卡情况:"+afternoonList1+"<---->当天打卡大小："+afternoonList1.size());
                    List<String> afternoonList2 = new LinkedList<String>();
                    for (String time6 : afternoonList1) {
                        if (time6.endsWith("1") && (time6.compareTo(attendanceOption.getEndtime()+":1") > 0)) {
                            afternoonList1.remove(time6);
                            break;
                        }
                    }
                    for (String clockOut : afternoonList1) {
                        if (clockOut.endsWith("2") || clockOut.endsWith("4") || clockOut.endsWith("6") || clockOut.endsWith("8")) {
                            afternoonList2.add(clockOut);
                        }
                    }
                    int afternoonList1Size = afternoonList1.size();
                    afternoonList1Size = (afternoonList2.size() >= 2) ? (afternoonList1Size - afternoonList2.size() + 1) : afternoonList1Size;
                    b.writeLog("当天下午修正过的打卡时间:" + afternoonList1 + ";下午集合大小:" + afternoonList1Size);
                    /*
                     *
                     * 计算带请假的迟到早退旷工小时数(周一-----周五下午)
                     *
                     * */
                    if (afternoonList1Size <= 1) {
                        countHours += Double.parseDouble(getDifferenceHours(attendanceOption.getAfternoonstarttime(), attendanceOption.getEndtime()));
                    } else if (afternoonList1Size == 2) {
                        //下午第一次打卡
                        String firstSign = afternoonList1.get(0);
                        //下午第一次打卡对应的分钟数
                        int firstSignForMin = getTimeMin(firstSign);
                        //下午第二次打卡
                        String secondSign = afternoonList1.get(1);
                        //下午第二次打卡对应的分钟数
                        int secondSignForMin = getTimeMin(secondSign);
                        if (firstSign.endsWith("1") && secondSign.endsWith("2")) {
                            //下午两次打卡数据 则计算迟到早退 13:30:00:1 17:00:00:2
                            lateTime += Math.max((firstSignForMin - getTimeMin(attendanceOption.getCompareafternoonin())), 0);
                            earlyTime += Math.max((getTimeMin(attendanceOption.getCompareafternoonout()) - secondSignForMin), 0);
                            List<String> LeaveList = getCurLeaveCondition(key3, id,attendanceOption);
                            Double relaxedHours = 0.0;
                            for (String leaveRecord : LeaveList) {
                                String startTime = leaveRecord.split(",")[1];
                                //如果请假开始时间大于17：15，则取17：15,如果开始时间小于13:00,则取13:00，其余情况则取默认值
                                startTime = getTimeMin(startTime) > getTimeMin(attendanceOption.getEndtime()) ? attendanceOption.getEndtime() : getTimeMin(startTime) < getTimeMin(attendanceOption.getAfternoonstarttime()) ? "13:00" : startTime;
                                String endTime = leaveRecord.split(",")[2];
                                //如果请假开始时间大于17：15，则取17：15,否则取默认值
                                endTime = getTimeMin(endTime) > getTimeMin(attendanceOption.getEndtime()) ? attendanceOption.getEndtime() : getTimeMin(endTime) < getTimeMin(attendanceOption.getAfternoonstarttime()) ? "13:00" : endTime;
                                relaxedHours += Double.parseDouble(getDifferenceHours(startTime, endTime));
                            }
                            actualWorkingHours += Double.parseDouble(getDifferenceHours(attendanceOption.getAfternoonstarttime(), attendanceOption.getEndtime())) - relaxedHours;
                        } else if (firstSign.endsWith("1") && !secondSign.endsWith("2")) {
                            //下午两次打卡记录， 14:00:00:1 16:00:00:4
                            Double relaxedHours = 0.0;
                            lateTime += ((firstSignForMin - getTimeMin(attendanceOption.getCompareafternoonin())) > 0) ? (firstSignForMin - getTimeMin(attendanceOption.getStarttime())) : 0;
                            countHours += ((getTimeMin(attendanceOption.getEndtime()) - secondSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (getTimeMin(attendanceOption.getEndtime()) - secondSignForMin) / 60)) : 0;
                            List<String> leaveRecordList = getCurLeaveCondition(key3, id,attendanceOption);//获取当天打卡记录 计算出请假小时数
                            for (String leaveRecord : leaveRecordList) {
                                String startTime = leaveRecord.split(",")[1];//请假开始时间
                                //如果请假开始时间大于17：15，则取17：15,如果开始时间小于13:00,则取13:00，其余情况则取默认值
                                startTime = getTimeMin(startTime) > getTimeMin(attendanceOption.getEndtime()) ? attendanceOption.getEndtime() : getTimeMin(startTime) < getTimeMin(attendanceOption.getAfternoonstarttime()) ? "13:00" : startTime;
                                String endTime = leaveRecord.split(",")[2];
                                //如果请假开始时间大于17：15，则取17：15,否则取默认值
                                endTime = getTimeMin(endTime) > getTimeMin(attendanceOption.getEndtime()) ? attendanceOption.getEndtime() : getTimeMin(endTime) < getTimeMin(attendanceOption.getAfternoonstarttime()) ? "13:00" : endTime;
                                relaxedHours += Double.parseDouble(getDifferenceHours(startTime, endTime));
                            }
                            actualWorkingHours += Double.parseDouble(getDifferenceHours(attendanceOption.getAfternoonstarttime(), attendanceOption.getEndtime())) - relaxedHours;
                        } else if (!firstSign.endsWith("1") && !secondSign.endsWith("2")) {
                            //下午两次请假数据 则计算旷工小数  14:00:00:3 16:00:00:4
                            countHours += (((firstSignForMin - getTimeMin(attendanceOption.getAfternoonstarttime())) > 0) ? Double.parseDouble(df11.format((float) (firstSignForMin - getTimeMin(attendanceOption.getAfternoonstarttime())) / 60)) : 0) +
                                    (((getTimeMin(attendanceOption.getEndtime()) - secondSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (getTimeMin(attendanceOption.getEndtime()) - secondSignForMin) / 60)) : 0);
                        } else if (!firstSign.endsWith("1") && secondSign.endsWith("2")) {
                            //下午两次打卡记录， 14:00:00:3 16:15:00:2
                            countHours += ((firstSignForMin - getTimeMin(attendanceOption.getAfternoonstarttime())) > 0) ? Double.parseDouble(df11.format((float) (firstSignForMin - getTimeMin(attendanceOption.getAfternoonstarttime())) / 60)) : 0;
                            earlyTime += Math.max((getTimeMin(attendanceOption.getCompareafternoonout()) - secondSignForMin), 0);
                            List<String> leaveRecordList = getCurLeaveCondition(key3, id,attendanceOption);//获取当天打卡记录 计算出请假小时数
                            String endTime;
                            for (String leaveRecord : leaveRecordList) {
                                endTime = leaveRecord.split(",")[2];//请假结束时间
                                //获取请假至下午的结束时间 20201221
                                if (getTimeMin(endTime) > getTimeMin(attendanceOption.getAfternoonstarttime())) {
                                    //b.writeLog("当前结束时间2:"+endTime);
                                    //b.writeLog(Double.parseDouble(getDifferenceHours(endTime,attendanceOption.getEndtime())));
                                    actualWorkingHours += Double.parseDouble(getDifferenceHours(endTime, attendanceOption.getEndtime()));//计算请假结束时间到17:15这段时间的实际工时
                                }
                            }
                        }
                    } else if (afternoonList1Size == 3) {
                        //下午第一次打卡
                        String firstSign = afternoonList1.get(0);
                        //下午第一次打卡对应的分钟数
                        int firstSignForMin = getTimeMin(firstSign);
                        //下午第二次打卡
                        String secondSign = afternoonList1.get(1);
                        //下午第二次打卡对应的分钟数
                        int secondSignForMin = getTimeMin(secondSign);
                        //下午第三次打卡
                        String thirdSign = afternoonList1.get(2);
                        //下午第三次打卡对应的分钟数
                        int thirdSignForMin = getTimeMin(thirdSign);
                        //下午第四次打卡
                        String forthSign = afternoonList1.get(3);
                        //下午第四次打卡对应的分钟数
                        int forthSignForMin = getTimeMin(forthSign);
                        if (firstSign.endsWith("1")) {
                            //上午三条记录 13：30：00：1  15：00：00：3 17：00：00：4
                            //上午第一次打卡时间前后计算旷工 第三次打卡时间计算旷工小时数
                            countHours += ((firstSignForMin - getTimeMin(attendanceOption.getAfternoonstarttime())) > 0) ? Double.parseDouble(df11.format((float) (firstSignForMin - getTimeMin(attendanceOption.getAfternoonstarttime())) / 60)) : 0;
                            countHours += ((secondSignForMin - firstSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (secondSignForMin - firstSignForMin) / 60)) : 0;
                            countHours += ((getTimeMin(attendanceOption.getEndtime()) - thirdSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (getTimeMin(attendanceOption.getEndtime()) - thirdSignForMin) / 60)) : 0;
                        } else if (thirdSign.endsWith("1")) {
                            //上午三条记录 13：30：00：3  15：00：00：4 17：00：00：1
                            //上午第一次打卡时间计算旷工小时数 第三次打卡时间前后计算旷工
                            countHours += ((firstSignForMin - getTimeMin(attendanceOption.getAfternoonstarttime())) > 0) ? Double.parseDouble(df11.format((float) (firstSignForMin - getTimeMin(attendanceOption.getAfternoonstarttime())) / 60)) : 0;
                            countHours += ((thirdSignForMin - secondSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (thirdSignForMin - secondSignForMin) / 60)) : 0;
                            countHours += ((getTimeMin(attendanceOption.getEndtime()) - thirdSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (getTimeMin(attendanceOption.getEndtime()) - thirdSignForMin) / 60)) : 0;
                        } else {
                            //下午请假两次情况 单独处理计算旷工小时数20201016
                            double leaveHour1 = ((secondSignForMin - firstSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (secondSignForMin - firstSignForMin) / 60)) : 0;
                            double leaveHour2 = ((forthSignForMin - thirdSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (forthSignForMin - thirdSignForMin) / 60)) : 0;
                            countHours += Double.parseDouble(getDifferenceHours(attendanceOption.getAfternoonstarttime(), attendanceOption.getEndtime())) - leaveHour1 - leaveHour2;
                        }
                    } else if (afternoonList1Size >= 4) {
                        //下午第一次打卡
                        String firstSign = afternoonList1.get(0);
                        //下午第一次打卡对应的分钟数
                        int firstSignForMin = getTimeMin(firstSign);
                        //下午第二次打卡
                        String secondSign = afternoonList1.get(1);
                        //下午第二次打卡对应的分钟数
                        int secondSignForMin = getTimeMin(secondSign);
                        //下午第三次打卡
                        String thirdSign = afternoonList1.get(2);
                        //下午第三次打卡对应的分钟数
                        int thirdSignForMin = getTimeMin(thirdSign);
                        //下午第四次打卡
                        String forthSign = afternoonList1.get(3);
                        //下午第四次打卡对应的分钟数
                        int forthSignForMin = getTimeMin(forthSign);
                        if (firstSign.endsWith("1")) {
                            //下午四条记录13：30：00：1 15:30:00:2 16：00：00：3 17：00：00：4
                            lateTime += Math.max((firstSignForMin - getTimeMin(attendanceOption.getCompareafternoonin())), 0);
                            earlyTime += Math.max((thirdSignForMin - secondSignForMin), 0);
                            countHours += ((getTimeMin(attendanceOption.getEndtime()) - forthSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (getTimeMin(attendanceOption.getEndtime()) - forthSignForMin) / 60)) : 0;
                            actualWorkingHours += Double.parseDouble(getDifferenceHours(attendanceOption.getAfternoonstarttime(), thirdSign));//计算下午1点到请假开始时间这段时间的实际工时
                        } else if (thirdSign.endsWith("1")) {
                            //下午四条记录 13：30：00：3 15:30:00:4 16：00：00：1 17：00：00：2
                            countHours += ((firstSignForMin - getTimeMin(attendanceOption.getAfternoonstarttime())) > 0) ? Double.parseDouble(df11.format((float) (firstSignForMin - getTimeMin(attendanceOption.getAfternoonstarttime())) / 60)) : 0;
                            lateTime += Math.max((thirdSignForMin - secondSignForMin), 0);
                            earlyTime += Math.max((getTimeMin(attendanceOption.getCompareafternoonout()) - forthSignForMin), 0);
                            actualWorkingHours += Double.parseDouble(getDifferenceHours(forthSign, attendanceOption.getEndtime()));//计算请假结束时间到17：15这段时间的实际工时
                        }
                    }
                    b.writeLog("当天日期5:" + key3 + ";当天迟到分钟数:" + lateTime + ";当天早退分钟数:" + earlyTime + ";当天下午旷工:" + countHours + ";当天下午实际工时:" + actualWorkingHours);
                }
            }

            curdayContion.setCurDate(key3);
            curdayContion.setLateTime(lateTime);
            curdayContion.setEarlyTime(earlyTime);
            b.writeLog("当天状态:"+attendanceUtil.getAttendanceStatus(key3).getAttendanceStatus());
            b.writeLog("当天迟到:"+lateTime+"当天早退："+earlyTime);
            if(attendanceUtil.getAttendanceStatus(key3).getAttendanceStatus().startsWith("2")){
                actualWorkingHours = actualWorkingHours*2;
                countHours = countHours*2;
                saturdayList1.add(key3);
            }
            if(attendanceUtil.getAttendanceStatus(key3).getAttendanceStatus().startsWith("0")){
                curdateList1.add(key3);
            }
            curdayContion.setCountHours(countHours);
            curdayContion.setActualWorkingHours(actualWorkingHours);
            curdayContionList.add(curdayContion);
        }
        curdateList.removeAll(curdateList1);
        for(String key:curdateList) {
            CurdayContion curdayContion1 = new CurdayContion();
            curdayContion1.setCurDate(key);
            curdayContion1.setLateTime(0.00);
            curdayContion1.setEarlyTime(0.00);
            curdayContion1.setCountHours(7.50);
            curdayContion1.setActualWorkingDay(0.00);
            curdayContionList.add(curdayContion1);
        }
        saturdayList.removeAll(saturdayList1);
        for(String key:saturdayList) {
            CurdayContion curdayContion2 = new CurdayContion();
            curdayContion2.setCurDate(key);
            curdayContion2.setLateTime(0.00);
            curdayContion2.setEarlyTime(0.00);
            curdayContion2.setCountHours(13.00);
            curdayContion2.setActualWorkingDay(0.00);
            curdayContionList.add(curdayContion2);
        }
        return curdayContionList;
    }

    public CurdayContion getActualDays(Map<String, List<String>> value,BaseBean b,List<String> curdateList, List<String> saturdayList, String id){
        CurdayContion curdayContion = new CurdayContion();
        Double actualDays = 0.0;
        for (String key3 : value.keySet()) {
            //当天打卡集合
            List<String> timesList = value.get(key3);
            Collections.sort(timesList);
            List<String> finalTimeList = finalTimeListController.getFinalTimeList(timesList);
            //对哺乳假数据进行处理
            List<String> newFinalTimeList= finalTimeListController.reviseFinalTimeList(finalTimeList,key3,id);
            if(curdateList.contains(key3)){
                List<String> morningList1=new LinkedList<String>();
                List<String> afternoonList1=new LinkedList<String>();
                for (String time5:newFinalTimeList){
                    int time5ForMin=getTimeMin(time5);
                    if(time5ForMin<720){
                        morningList1.add(time5);
                        Collections.sort(morningList1);
                    }else{
                        afternoonList1.add(time5);
                        Collections.sort(afternoonList1);
                    }
                }
                //上午未打签到卡，签到签退再11：45之后打
                for(String time6:morningList1){
                    if(time6.endsWith("1")&&(time6.compareTo("11:45:00:1")>0)){
                        morningList1.remove(time6);
                        break;
                    }
                }
                actualDays +=(morningList1.size()<=1)?0:0.5;
                List<String> afternoonList2=new LinkedList<String>();
                for(String time6:afternoonList1){
                    if(time6.endsWith("1")&&(time6.compareTo("17:15:00:1")>0)){
                        afternoonList1.remove(time6);
                        break;
                    }
                }
                for(String clockOut:afternoonList1){
                    if(clockOut.endsWith("2")){
                        afternoonList2.add(clockOut);
                    }
                }
                int afternoonList1Size=afternoonList1.size();
                afternoonList1Size=(afternoonList2.size()>=2)?(afternoonList1Size-afternoonList2.size()+1):afternoonList1Size;
                actualDays +=(afternoonList1Size<=1)?0:0.5;
            }else if(saturdayList.contains(key3)){
                List<String> morningList1=new LinkedList<String>();
                List<String> afternoonList1=new LinkedList<String>();
                for (String time5:newFinalTimeList){
                    int time5ForMin=getTimeMin(time5);
                    if(time5ForMin<720){
                        morningList1.add(time5);
                        Collections.sort(morningList1);
                    }else{
                        afternoonList1.add(time5);
                        Collections.sort(afternoonList1);
                    }
                }
                for(String time6:morningList1){
                    if(time6.endsWith("1")&&(time6.compareTo("11:45:00:1")>0)){
                        morningList1.remove(time6);
                        break;
                    }
                }
                actualDays +=(morningList1.size()<=1)?0:0.5;
                List<String> afternoonList2=new LinkedList<String>();
                for(String time6:afternoonList1){
                    if(time6.endsWith("1")&&(time6.compareTo("16:15:00:1")>0)){
                        afternoonList1.remove(time6);
                        break;
                    }
                }
                for(String clockOut:afternoonList1){
                    if(clockOut.endsWith("2")){
                        afternoonList2.add(clockOut);
                    }
                }
                int afternoonList1Size=afternoonList1.size();
                afternoonList1Size=(afternoonList2.size()>=2)?(afternoonList1Size-afternoonList2.size()+1):afternoonList1Size;
                actualDays +=(afternoonList1Size<=1)?0:0.5;
            }
        }
        curdayContion.setActualWorkingDay(actualDays);
        return curdayContion;
    }

    public static int getTimeMin(String curTime) {
        return Integer.parseInt(curTime.split(":")[0]) * 60 + Integer.parseInt(curTime.split(":")[1]);
    }

    private static String getDifferenceHours(String startTime, String endTime) {
        DecimalFormat df = new DecimalFormat("0.00");
        int firstSignForMin1 = getTimeMin(startTime);//第一次打卡对应的分钟数
        int secondSignForMin1 = getTimeMin(endTime);//第二次打卡对应的分钟数
        return df.format((float) (secondSignForMin1 - firstSignForMin1) / 60);
    }

    private static List<String> getCurLeaveCondition(String curdate, String id,AttendanceOption attendanceOption) {
        String getLeaveSql = "select * from uf_AskForLeave where userid='" + id + "'  and type in (0,8,9) and start_date>='" + curdate + "' and end_date<= '" + curdate + "'";
        RecordSet getLeaveRs = new RecordSet();
        //b.writeLog("当月请假sql语句为:"+getLeaveSql);
        getLeaveRs.execute(getLeaveSql);
        String leaveRecord = "";
        List<String> leaveRecordList = new ArrayList<String>();
        //获取当天请假日期 请假开始时间 请假结束时间
        while (getLeaveRs.next()) {
            String startDate = Util.null2String(getLeaveRs.getString("start_date"));
            //调休(年假)请假结束日期
            String endDate = Util.null2String(getLeaveRs.getString("end_date"));
            //调休(年假)请假开始时间
            String startTime = Util.null2String(getLeaveRs.getString("start_time"));
            //调休(年假)请假结束时间
            String endTime = Util.null2String(getLeaveRs.getString("end_time"));
            //获取请假当天出勤状态 0全天出勤 1非出勤 2出勤半天
            String status = getAttendanceStatus(curdate);
            if (startDate.equals(endDate)) {
                //如果请假天数为1天
                if (status.startsWith("0")) {
                    //请假开始时间小于08:30则默认为08：30；请假结束时间大于17：15则默认为17：15 请假记录格式为 请假日期，开始时间，结束时间
                    startTime = startTime.compareTo(attendanceOption.getStarttime()) <= 0 ? attendanceOption.getStarttime() : startTime;
                    endTime = endTime.compareTo(attendanceOption.getEndtime()) >= 0 ? attendanceOption.getEndtime() : endTime;
                    leaveRecord = curdate + "," + startTime + "," + endTime;
                } else if (status.startsWith("2")) {
                    //请假开始时间小于08:30则默认为08：30；请假结束时间大于11：45则默认为11：45 请假记录格式为 请假日期，开始时间，结束时间
                    startTime = startTime.compareTo(attendanceOption.getStarttime()) <= 0 ? attendanceOption.getStarttime() : startTime;
                    endTime = endTime.compareTo(attendanceOption.getMorningendtime()) >= 0 ? attendanceOption.getMorningendtime() : endTime;
                    leaveRecord = curdate + "," + startTime + "," + endTime;
                }
            } else {
                //如果请假天数大于1天
                if (curdate.equals(startDate)) {
                    //当天为开始日期
                    if (status.startsWith("0")) {
                        //请假开始时间大于17:15则默认为17:15；请假结束时间默认为17：15 请假记录格式为 请假日期，开始时间，结束时间
                        startTime = startTime.compareTo(attendanceOption.getEndtime()) >= 0 ? attendanceOption.getEndtime() : startTime;
                        endTime = attendanceOption.getEndtime();
                        leaveRecord = curdate + "," + startTime + "," + endTime;
                    } else if (status.startsWith("2")) {
                        //请假开始时间大于11:45则默认为11:45；请假结束时间默认为11:45 请假记录格式为 请假日期，开始时间，结束时间
                        startTime = startTime.compareTo(attendanceOption.getMorningendtime()) >= 0 ? attendanceOption.getMorningendtime() : startTime;
                        endTime = attendanceOption.getMorningendtime();
                        leaveRecord = curdate + "," + startTime + "," + endTime;
                    }
                } else if (curdate.equals(endDate)) {
                    //当天为结束日期
                    if (status.startsWith("0")) {
                        //请假开始时间默认为08:30；请假结束时间大于17：15则默认为17：15 请假记录格式为 请假日期，开始时间，结束时间
                        startTime = attendanceOption.getStarttime();
                        endTime = endTime.compareTo(attendanceOption.getEndtime()) >= 0 ? attendanceOption.getEndtime() : endTime;
                        leaveRecord = curdate + "," + startTime + "," + endTime;
                    } else if (status.startsWith("2")) {
                        //请假开始时间默认为08:30；请假结束时间大于11：45则默认为11：45 请假记录格式为 请假日期，开始时间，结束时间
                        startTime = attendanceOption.getStarttime();
                        endTime = endTime.compareTo(attendanceOption.getMorningendtime()) >= 0 ? attendanceOption.getMorningendtime() : endTime;
                        leaveRecord = curdate + "," + startTime + "," + endTime;
                    }
                } else {
                    //当天不为开始日期和结束日期
                    if (status.startsWith("0")) {
                        //请假开始时间默认为08:30；请假结束时间则默认为17：15 请假记录格式为 请假日期，开始时间，结束时间
                        startTime = attendanceOption.getStarttime();
                        endTime = attendanceOption.getEndtime();
                        leaveRecord = curdate + "," + startTime + "," + endTime;
                    } else if (status.startsWith("2")) {
                        //请假开始时间默认为08:30；请假结束时间则默认为11：45 请假记录格式为 请假日期，开始时间，结束时间
                        startTime = attendanceOption.getStarttime();
                        endTime = attendanceOption.getMorningendtime();
                        leaveRecord = curdate + "," + startTime + "," + endTime;
                    }
                }
            }
            //将请假记录统一放入到集合中
            leaveRecordList.add(leaveRecord);
        }
        return leaveRecordList;
    }

    private static String getAttendanceStatus(String curdate) {
        String getAttendanceStatusSql = "select attendanceStatus from uf_attendance where curdate like '%" + curdate + "%'";
        return getName(getAttendanceStatusSql);
    }

    public static String getName(String sql) {
        RecordSet recordSet = new RecordSet();
        recordSet.execute(sql);
        recordSet.next();
        return recordSet.getString(1);
    }


    /**
     * 获取用户当前月对应的每天排班情况
     * @param id
     * @param likeDate
     * @return
     */
    public List<AttendanceOption> getAttendanceCondition(String id,String likeDate){
        String endDate = attendanceUtil.getEndDate(likeDate);
        for (int i = 1 ;i <= Integer.parseInt(endDate.split("-")[2]) ;i++ ){

        }
        RecordSet recordSet = new RecordSet();
        List<AttendanceOption> attendanceOptionList = new LinkedList<AttendanceOption>();
        String sql = "select (select id from hrmresource where id="+id+"),u1.curdate,u2.attendancestatus,u2.starttime,u2.endtime," +
                " u2.morningendtime,u2.afternoonstarttime,u2.FREQUENCY,u2.MORNINGENDTIME1,u2.COMPAREMORNINGIN,u2.COMPAREMORNINGOUT," +
                "u2.COMPAREAFTERNOONIN,u2.COMPAREAFTERNOONOUT from uf_attendance u1 LEFT JOIN uf_AttendanceTime u2 on u1.attendancestatus = u2.attendancestatus " +
                "where u2.groupid in (select subcompanyid1 from hrmresource where id="+id+") and u1.curdate " +
                "like '%"+likeDate+"%' ORDER BY u1.curdate ";
        BaseBean b = new BaseBean();
        b.writeLog("查询排班具体:"+sql);
        recordSet.execute(sql);
        while (recordSet.next()){
            AttendanceOption attendanceOption = new AttendanceOption();
            attendanceOption.setUserid(id);
            //attendanceOption.setAttendancestatus(recordSet.getInt("attendancestatus"));
            attendanceOption.setCurDate(recordSet.getString("curdate"));
            attendanceOption.setStarttime(recordSet.getString("starttime"));
            attendanceOption.setEndtime(recordSet.getString("endtime"));
            attendanceOption.setMorningendtime(recordSet.getString("morningendtime"));
            attendanceOption.setAfternoonstarttime(recordSet.getString("afternoonstarttime"));
            attendanceOption.setFrequency(recordSet.getInt("FREQUENCY"));
            attendanceOption.setMorningendtime1(recordSet.getString("MORNINGENDTIME1"));
            attendanceOption.setComparemorningin(recordSet.getString("COMPAREMORNINGIN"));
            attendanceOption.setComparemorningout(recordSet.getString("COMPAREMORNINGOUT"));
            attendanceOption.setCompareafternoonin(recordSet.getString("COMPAREAFTERNOONIN"));
            attendanceOption.setCompareafternoonout(recordSet.getString("COMPAREAFTERNOONOUT"));
            attendanceOptionList.add(attendanceOption);
        }
        return attendanceOptionList;
    }

    /**
     * 获取用户某天对应的排班情况
     * @param id
     * @param curdate
     * @return
     */
    public AttendanceOption getSingleAttendanceCondition(String id,String curdate){
        RecordSet recordSet = new RecordSet();
        RecordSet recordSet1 = new RecordSet();
        String sql = "select NVL(max(u2.attendancestatus),-1) from ECOLOGY8.UF_GROUP1  u1 LEFT JOIN uf_attendancetime u2 on u1.groupid = u2.groupid " +
                "where dateid2 like '%"+curdate+"%' and (userid like '"+id+",%' or userid like '%,"+id+"' or userid like '%,"+id+",%')";
        BaseBean b = new BaseBean();
        recordSet.execute(sql);
        recordSet.next();
        String attendancestatus = recordSet.getString(1);
        if(attendancestatus.equals("-1")){
            if(dayForWeeks(curdate) <= 5){
                attendancestatus = "0";
            }
            if(dayForWeeks(curdate) > 5){
                attendancestatus = "1";
            }
        }
        b.writeLog("查询排班具体:"+sql+";查询结果为:"+attendancestatus);

        String sql1 = "select u2.attendancestatus,u2.starttime,u2.endtime," +
                " u2.morningendtime,u2.afternoonstarttime,u2.FREQUENCY,u2.MORNINGENDTIME1,u2.COMPAREMORNINGIN,u2.COMPAREMORNINGOUT," +
                "u2.COMPAREAFTERNOONIN,u2.COMPAREAFTERNOONOUT  uf_AttendanceTime u2 where  u2.attendancestatus ='"+attendancestatus+"'";
        recordSet1.execute(sql1);
        AttendanceOption attendanceOption = new AttendanceOption();
        attendanceOption.setUserid(id);
        attendanceOption.setAttendancestatus(attendancestatus);
        attendanceOption.setCurDate(curdate);
        attendanceOption.setStarttime(recordSet.getString("starttime"));
        attendanceOption.setEndtime(recordSet.getString("endtime"));
        attendanceOption.setMorningendtime(recordSet.getString("morningendtime"));
        attendanceOption.setAfternoonstarttime(recordSet.getString("afternoonstarttime"));
        attendanceOption.setFrequency(recordSet.getInt("FREQUENCY"));
        attendanceOption.setMorningendtime1(recordSet.getString("MORNINGENDTIME1"));
        attendanceOption.setComparemorningin(recordSet.getString("COMPAREMORNINGIN"));
        attendanceOption.setComparemorningout(recordSet.getString("COMPAREMORNINGOUT"));
        attendanceOption.setCompareafternoonin(recordSet.getString("COMPAREAFTERNOONIN"));
        attendanceOption.setCompareafternoonout(recordSet.getString("COMPAREAFTERNOONOUT"));
        return attendanceOption;
    }


    /**
     * 根据日期获取对应的星期几
     * @param pTime
     * @return
     */
    public int  dayForWeeks(String pTime) {
        SimpleDateFormat format = new  SimpleDateFormat("yyyy-MM-dd" );
        Calendar c = Calendar.getInstance();
        try {
            c.setTime(format.parse(pTime));
        } catch (ParseException e) {
            e.printStackTrace();
        }
        int  dayForWeek = 0 ;
        if (c.get(Calendar.DAY_OF_WEEK) == 1 ){
            dayForWeek = 7 ;
        }else {
            dayForWeek = c.get(Calendar.DAY_OF_WEEK) - 1 ;
        }
        return  dayForWeek;
    }


}

