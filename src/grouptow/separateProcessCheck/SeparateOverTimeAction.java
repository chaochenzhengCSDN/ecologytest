package weaver.iiot.grouptow.attendanceProject.overtimeapply;

import weaver.conn.RecordSet;
import weaver.iiot.grouptow.attendanceProject.overtimeapply.entity.OverTimeInfoEntity;
import weaver.iiot.grouptow.util.StringUtil;
import weaver.interfaces.workflow.action.Action;
import weaver.soa.workflow.request.RequestInfo;

import java.util.LinkedList;
import java.util.List;

/**
 * 将加班流程数据插入到加班表
 */
public class SeparateOverTimeAction implements Action {
    private static final String name="overTimeAction";
    @Override
    public String execute(RequestInfo request) {
        String requestId=request.getRequestid();
        try {
            List<OverTimeInfoEntity> overTimeList1 = selectWorkMoreTimeByRequestId(requestId);
            StringUtil.writeLog(name,overTimeList1);
            for(OverTimeInfoEntity overTimeInfoEntity:overTimeList1){
                String company=overTimeInfoEntity.getCompany();
                String depart=overTimeInfoEntity.getDepart();
                int overtimeType=overTimeInfoEntity.getOvertimeType();
                String dateTime=overTimeInfoEntity.getDateTime();
                Double overtimeHours=overTimeInfoEntity.getOvertimeHours();
                String userId=overTimeInfoEntity.getUserId();
                int breakOff=overTimeInfoEntity.getBreak_off();
                //根据工作日其计算当天星期 break_off=0调休 正常工作日0
                String selectSql1="select week,isAttendance,isHoliday from uf_attendance where curdate='"+dateTime+"' ";
                RecordSet rs3 = new RecordSet();
                rs3.executeSql(selectSql1);
                StringUtil.writeLog(name,selectSql1);
                String validateTime=getNextThirdMonth(dateTime);
                StringUtil.writeLog(name,validateTime);
                String month=validateTime.substring(5,7);
                while(rs3.next()){
                    int week=rs3.getInt("week");
                    int isAttendance=rs3.getInt("isAttendance");
                    int isHoliday=rs3.getInt("isHoliday");
                    //将工作日加班且不调休插入到时间池A
                    if(breakOff==1){
                        String insertSql1="insert into uf_TimePoolA" +
                         "(ID,REQUESTID,WEEK,ISWORKDAY,ISEFFECTIVE,COMPANY,DEPART,WORKDATE,OVERTIME_HOURS,USERID)" +
                         "values" +
                         "(null,"+requestId+","+week+","+isAttendance+",0,'"+ company+"','"+depart+"','"+dateTime+"','"+overtimeHours+"',"+userId+")";
                        RecordSet rs1 = new RecordSet();
                        rs1.executeSql(insertSql1);
                        StringUtil.writeLog(name,insertSql1);
                    }
                    //将非工作日加班且调休加入时间池B
                    if(breakOff==0){
                        String insertSql2="insert into uf_TimePoolB" +
                         "(ID,REQUESTID,WEEK,COMPANY,DEPART,WORKDATE,OVERTIME_HOURS,ISEFFECTIVE,VALIDATE_TIME,USERID)" +
                         "values" +
                         "(null,"+requestId+","+week+",'"+company+"','"+depart+"','"+dateTime+"',"+overtimeHours+",0,'"+validateTime+"',"+userId+")";
                        RecordSet rs4 = new RecordSet();
                        rs4.executeSql(insertSql2);
                        StringUtil.writeLog(name,insertSql2);
                    }
                }
                //将加班数据插入加班表
                String startTime=overTimeInfoEntity.getStartTime();
                String endTime=overTimeInfoEntity.getEndTime();
                String insertSql="insert into uf_WorkOvertime" +
                 "(ID,REQUESTID,COMPANY,DEPART,USERID,OVERTIME_HOURS,OVERTIME_TYPE,WORK_DATE,START_TIME,END_TIME,BREAK_OFF)" +
                 "values" +
                 "(null,"+requestId+",'"+company+"','"+depart+"',"+userId+","+overtimeHours+","+overtimeType+",'"+dateTime+"','"+startTime+"','"+endTime+"',"+breakOff+")";
                RecordSet rs2 = new RecordSet();
                rs2.executeSql(insertSql);
                StringUtil.writeLog(name,insertSql);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return Action.SUCCESS;
    }

    /**
     * 根据requestId查询出对应的加班时间
     * @param requestId
     * @return
     * @throws Exception
     */
    private List<OverTimeInfoEntity> selectWorkMoreTimeByRequestId(String requestId) throws Exception{
        RecordSet rs = new RecordSet();
        //根据requestid查询记录
        String selectSql="SELECT * FROM formtable_main_618 a LEFT JOIN formtable_main_618_dt1 b ON a.id=b.mainid where a.requestid='"+requestId+"' ";
        rs.executeSql(selectSql);
        StringUtil.writeLog(name,selectSql);     
        List<OverTimeInfoEntity> overTimeList=new LinkedList< OverTimeInfoEntity>();
        while(rs.next()){
            int selectvalue = rs.getInt("company");
            int selectvalueDepart = rs.getInt("depart");
            //根据selectvalue查询selectname
            String selectSql2 = "select selectname from workflow_selectitem where FIELDID=216558 and selectvalue="+selectvalue+"";
            String selectSql3 = "select departmentname from hrmdepartment where id="+selectvalueDepart+"";
            String company = getName(selectSql2,"OA");
            String depart = getName(selectSql3,"OA");
            OverTimeInfoEntity overTimeInfoEntity=new OverTimeInfoEntity();
            overTimeInfoEntity.setCompany(company);
            overTimeInfoEntity.setDepart(depart);
            overTimeInfoEntity.setDateTime(rs.getString("date_time"));
            overTimeInfoEntity.setOvertimeHours(rs.getDouble("overtime_hours"));
            overTimeInfoEntity.setOvertimeType(rs.getInt("type"));
            overTimeInfoEntity.setStartTime(rs.getString("start_time"));
            overTimeInfoEntity.setEndTime(rs.getString("end_time"));
            overTimeInfoEntity.setUserId(rs.getString("name"));
            overTimeInfoEntity.setBreak_off(rs.getInt("break_off"));
            overTimeList.add(overTimeInfoEntity);
        }
        return overTimeList;
    }

    /**
     * 获取三个自然月的后的1号
     * @param time1
     * @return
     * @throws Exception
     */
    private static String getNextThirdMonth(String time1){
        String year1=time1.substring(0,4);
        int year2=Integer.parseInt(year1)+1;
        String month1=time1.substring(5,7);
        String month3=new String();
        int month2=Integer.parseInt(month1);
        if(month2<=8){
            month2 +=4;
            if(month2<=9){
                month3="0"+ String.valueOf(month2);
            }else {
                month3=String.valueOf(month2);
            }
        }else{
            year1=String.valueOf(year2) ;
            month2 =month2+4-12;
            month3="0"+ String.valueOf(month2);
        }
        time1 =year1+"-"+month3+"-01";
        return time1;
    }
    public String getName(String sql,String DateSource)throws Exception{
        RecordSet recordSet=new RecordSet();
        recordSet.executeSql(sql,DateSource);
        recordSet.next();
        String name=recordSet.getString(1);
        return name;
    }
}
