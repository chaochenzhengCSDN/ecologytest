package weaver.iiot.grouptow.common;

import com.weaver.general.Util;
import weaver.conn.RecordSet;
import weaver.iiot.grouptow.util.AttendanceUtil;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;
import java.util.Map;

public class BusinessCommonController {

    AttendanceUtil attendanceUtil=new AttendanceUtil();
    public void changeBusinessTripTime(Map<String, List<String>> value, String checkMinDate, String checkMaxDate, String id, String month, String businessinFlag, String businessOutFlag) {
        LeaveCommonController leaveCommonController=new LeaveCommonController();
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
        String signInTime = "08:30:00:" + businessinFlag;
        String signBackTime = "11:45:00:" + businessOutFlag;
        String signInSecondTime = "13:00:00:" + businessinFlag;
        String signBackSecondTime = "17:15:00:" + businessOutFlag;
        List<String> businesstripTimeList1 = new ArrayList<String>();//全天标准打卡数据 上午签到时间 上午签退时间 下午签到时间 下午签退时间
        businesstripTimeList1.add(signInTime);
        businesstripTimeList1.add(signBackTime);
        businesstripTimeList1.add(signInSecondTime);
        businesstripTimeList1.add(signBackSecondTime);
        String sql1 = "SELECT start_date,start_time,end_date,end_time from uf_BusinessTrip WHERE userid = '" + id + "' and (start_date like '%" + month + "%' or end_date like '%" + month + "%') ORDER BY start_date";
        RecordSet rs1 = new RecordSet();
        rs1.execute(sql1);
        //b.writeLog("出差记录查询sql:" + sql1);
        while (rs1.next()) {
            List<String> dateList = new ArrayList<String>();
            List<String> finalDateList = new ArrayList<String>();
            //出差开始日期
            String startDate = Util.null2String(rs1.getString("start_date"));
            //出差结束日期
            String endDate = Util.null2String(rs1.getString("end_date"));
            //出差开始时间
            String startTime = Util.null2String(rs1.getString("start_time"));
            //出差结束时间
            String endTime = Util.null2String(rs1.getString("end_time"));
            if(!startDate.contains(month)){
                startDate = month+"-01";
                startTime = "08:30";
            }
            if(!endDate.contains(month)){
                endDate = attendanceUtil.getEndDate(month);
                endTime = "17:15";
            }

            //1.处理出差期间的考勤打卡时间(不包括出差开始日期和出差结束日期)
            Calendar c1 = Calendar.getInstance();
            try {
                c1.setTime(sdf.parse(startDate));
                long time = sdf.parse(endDate).getTime();
                for (long d = c1.getTimeInMillis(); d <= time; d = getTimeMillis(c1)) {
                    dateList.add(sdf.format(d));
                }
                for (int i = 1; i < dateList.size() - 1; i++) {
                    String businesstripDate = dateList.get(i);
                    if (Integer.parseInt(businesstripDate.split("-")[1]) == Integer.parseInt(month.split("-")[1])) {
                        finalDateList.add(dateList.get(i));
                    }
                }
                for (String businesstripDate : finalDateList) {
                    //根据用户id和日期查询当天是否有业务考勤打卡记录
                    String attendanceSql1 = "SELECT count(*) count from mobile_sign ms,hrmresource hre WHERE ms.operater = hre.id and hre.id = " + id + " and ms.operate_date = '" + businesstripDate + "'";
                    ////b.writeLog("出差开始日期是否有打卡记录:"+attendanceSql1);
                    int isAttendance1 = getId(attendanceSql1);
                    if (isAttendance1 >= 1) {
                        value.put(businesstripDate, businesstripTimeList1);
                    }
                }
                //根据用户id和日期查询出差开始当天是否有业务考勤打卡记录
                String attendanceSql2 = "SELECT count(*) count from mobile_sign ms,hrmresource hre WHERE ms.operater = hre.id and hre.id = " + id + " and ms.operate_date = '" + startDate + "'";
                String attendanceSql3 = "SELECT count(*) count from mobile_sign ms,hrmresource hre WHERE ms.operater = hre.id and hre.id = " + id + " and ms.operate_date = '" + endDate + "'";
                ////b.writeLog("出差开始日期是否有打卡记录:"+attendanceSql2);
                int isAttendance2 = getId(attendanceSql2);
                int isAttendance3 = getId(attendanceSql3);
                //出差开始日期和出差结束日期不是同一天
                if (!startDate.equals(endDate)) {
                    //2.处理出差开始当天的考勤打卡时间
                    //出差开始日期当天的打卡记录集合
                    //List<String> businesstripStartDate = value.get(startDate);
                    if (isAttendance2 >= 1) {
                        endTime = "17:15";
                        leaveCommonController.changeTodayTime(value, startTime, endTime, startDate, businessinFlag, businessOutFlag);
                    }
                    if (isAttendance3 >= 1) {
                        startTime = Integer.parseInt(startTime.split(":")[0]) * 60 + Integer.parseInt(startTime.split(":")[1]) >= 510 ? "08:30" : startTime;
                        leaveCommonController.changeTodayTime(value, startTime, endTime, startDate, businessinFlag, businessOutFlag);
                    }
                } else {
                    //无业务考勤打卡记录
                    if(isAttendance2>=1){
                        //调用出差方法，处理当天的打卡时间
                        leaveCommonController.changeTodayTime(value, startTime, endTime, startDate, businessinFlag, businessOutFlag);
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
    public Long getTimeMillis(Calendar c){
        c.set(Calendar.DAY_OF_MONTH, c.get(Calendar.DAY_OF_MONTH) + 1);
        return c.getTimeInMillis();
    }
    public int getId(String getCompanyIdSql){
        RecordSet recordSet = new RecordSet();
        recordSet.execute(getCompanyIdSql);
        recordSet.next();
        return recordSet.getInt(1);
    }
}