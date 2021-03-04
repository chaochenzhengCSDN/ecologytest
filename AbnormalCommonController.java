package weaver.iiot.grouptow.common;

import com.weaver.general.Util;
import weaver.conn.RecordSet;

import java.util.LinkedList;
import java.util.List;
import java.util.Map;

public class AbnormalCommonController {
    public void changeAbnormalSignTime(Map<String, List<String>> value, String id, String month) {
        String sql = "SELECT abnormal_date,morning_sign_in,morning_sign_back,afternoon_sign_in,afternoon_sign_back from UF_ABNORMALSIGN  WHERE abnormal_date like '%" + month + "%' AND userid = " + id + "";
        RecordSet rs = new RecordSet();
        rs.execute(sql);
        //b.writeLog("异常考勤sql:"+sql);
        while (rs.next()) {
            String abnormalDate = Util.null2String(rs.getString("abnormal_date"));//考勤异常日期
            String morningSignIn = Util.null2String(rs.getString("morning_sign_in")); //上午签到考勤异常
            String morningSignBack = Util.null2String(rs.getString("morning_sign_back")); //上午签退考勤异常
            String afternoonSignIn = Util.null2String(rs.getString("afternoon_sign_in")); //下午签到考勤异常
            String afternoonSignBack = Util.null2String(rs.getString("afternoon_sign_back")); //下午签退考勤异常
            ////b.writeLog("当月集合:"+value);
            List<String> abnormalSignDate=new LinkedList<String>();
            if(value.containsKey(abnormalDate)){
                abnormalSignDate = value.get(abnormalDate); //获取考勤异常当天的打卡时间集合
            }
            ////b.writeLog("当天异常日期："+abnormalDate+"异常数据:"+abnormalSignDate);
            // 异常类型 上午签到 添加上午签到标准时间 上午签退 添加上午签退标准时间 下午签到 添加下午签到标准时间 下午签退 添加下午签退标准时间
            if (morningSignIn.equals("1")) {
                abnormalSignDate.add("08:30:00:1");
                value.put(abnormalDate, abnormalSignDate);
            }
            if (morningSignBack.equals("1")) {
                abnormalSignDate.add("11:45:00:2");
                value.put(abnormalDate, abnormalSignDate);
            }
            if (afternoonSignIn.equals("1")) {
                abnormalSignDate.add("13:00:00:1");
                value.put(abnormalDate, abnormalSignDate);
            }
            if (afternoonSignBack.equals("1")) {
                abnormalSignDate.add("17:15:00:2");
                value.put(abnormalDate, abnormalSignDate);
            }
        }
    }
}