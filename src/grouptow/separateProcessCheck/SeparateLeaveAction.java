package weaver.iiot.grouptow.attendanceProject.leaveapply;

import weaver.conn.RecordSet;
import weaver.iiot.grouptow.attendanceProject.leaveapply.entity.LeaveEntity;
import weaver.interfaces.workflow.action.Action;
import weaver.soa.workflow.request.RequestInfo;

import java.math.BigDecimal;
import java.text.SimpleDateFormat;
import java.util.*;

/**
 * 请假流程 将请假数据更新到数据库中，同时更新加班池B以及年假表数据
 */
public class SeparateLeaveAction implements Action {
    private static final String name = "leaveAction";
    private static final String annualName = "annualAction";

    @Override
    public String execute(RequestInfo request) {
        String requestId = request.getRequestid();
        LeaveEntity leaveEntity1 = new LeaveEntity();
        StringUtil.writeLog(name, requestId);
        Double realHours = 0.0;//定义实际的请假小时数
        Double realDays = 0.0;//定义实际的请假天数
        Double dHours = 0.0;//定义需要更新时间池B的变量
        try {
            leaveEntity1 = selectKaoQinByRequestId(requestId);
            Double hours = leaveEntity1.getHours();//获取请假小时数
            String applicationDate1 = leaveEntity1.getApplicationDate();//获取开始日期
            //判断必要条件是否存在
            if (StringUtil.isNull(leaveEntity1.getStartDate()) || StringUtil.isNull(leaveEntity1.getUserId())) {
                request.getRequestManager().setMessageid(requestId);
                request.getRequestManager().setMessagecontent("流程信息不存在！");
                return Action.FAILURE_AND_CONTINUE;
            }
            //将请假数据插入请假表
            String company = leaveEntity1.getCompany();
            String depart = leaveEntity1.getDepart();
            String userId = leaveEntity1.getUserId();
            int type = leaveEntity1.getType();
            String applicationDate = leaveEntity1.getApplicationDate();
            String startDate = leaveEntity1.getStartDate();
            String startTime = leaveEntity1.getStartTime();
            int startTimeMin = getTimeMin(startTime, 0) * 60 + getTimeMin(startTime, 1);//当前记录开始时间的分钟数
            String endDate = leaveEntity1.getEndDate();
            String endTime = leaveEntity1.getEndTime();
            int endTimeMin = getTimeMin(endTime, 0) * 60 + getTimeMin(endTime, 1);//当前记录结束时间的分钟数
            Double days = leaveEntity1.getDays();
            String startTime1 = leaveEntity1.getStartTime1();
            String endTime1 = leaveEntity1.getEndTime1();
            int frequency = leaveEntity1.getFrequency();
            //如果不存在当天的记录则存储当天的记录
            List<LeaveEntity> curLeaveEntityList = getRelateConditionDate(startDate, endDate, userId);//根据流程数据开始日期、结束日期以及类型查询是否有当天记录
            if (curLeaveEntityList.size() > 0) {
                for (LeaveEntity leaveEntity : curLeaveEntityList) {
                    Double recordDay = leaveEntity.getDays();//归档请假记录折算天数
                    Double recordHour = leaveEntity.getHours();//归档请假记录折算小时数
                    String recordStartTime = leaveEntity.getStartTime();//归档请假记录开始时间
                    int recordStartTimeMin = getTimeMin(recordStartTime, 0) * 60 + getTimeMin(recordStartTime, 1);//归档请假记录开始时间的分钟数
                    String recordEndTime = leaveEntity.getEndTime();//归档请假记录结束时间
                    int recordEndTimeMin = getTimeMin(recordEndTime, 0) * 60 + getTimeMin(recordEndTime, 1);//归档请假记录结束时间的分钟数
                    int recordType = leaveEntity.getType();//归档请假记录请假类型
                    int recordRequestId = leaveEntity.getRequestId();//归档请假记录的requestId
                    //比较两组数据的时间 历史记录 09：20-11：45 当前申请 08：30-09：30   历史记录 08：30-10:00  当前申请 10:00-11:45
                    StringUtil.writeLog("历史记录开始时间", recordStartTimeMin);
                    StringUtil.writeLog("历史记录结束时间", recordEndTimeMin);
                    StringUtil.writeLog("当前记录开始时间", startTimeMin);
                    StringUtil.writeLog("当前记录结束时间", endTimeMin);
                    //历史记录为11：10-14：15 当前申请08：30-11：45只需要补全左侧
                    if (recordStartTimeMin >= startTimeMin && recordStartTimeMin <= endTimeMin && recordEndTimeMin >= endTimeMin) {
//                        int d_Hours=(endTimeMin-recordStartTimeMin)/60;//重复的请假时间分钟数
                        //11：45对应分钟数:705min 13:00对应分钟数780min
                        if (recordStartTimeMin <= 705) {
                            if (endTimeMin >= 705 && endTimeMin <= 780) {
                                endTimeMin = 705;
                            } else if (endTimeMin > 780) {
                                endTimeMin = endTimeMin - 75;
                            } else {
                                endTimeMin = endTimeMin;
                            }
                        }
                        dHours = getDouble((double) (endTimeMin - recordStartTimeMin) / 60);
                        StringUtil.writeLog("该记录与之前记录有重合为：", dHours);
                        StringUtil.writeLog("该记录小时数为：", hours);
                        StringUtil.writeLog("之前记录小时数为：", recordHour);
                        realHours = hours + recordHour - dHours;
                        realHours = getDouble(realHours);//请假小时数保留两位小数
                        StringUtil.writeLog("该记录实际请假小时数为：", realHours);
                        realDays = realHours / 7.5;
                        realDays = getDouble(realDays);//请假天数保留两位小数
                        String updateLeaveSql = "update uf_AskForLeave set start_date='"+startDate+"',start_time='" + startTime + "',hours=" + realHours + ",days=" + realDays + " where requestid=" + recordRequestId + " ";
                        StringUtil.writeLog(name, updateLeaveSql);
                        StringUtil.writeLog("符合补全左侧条件:", startTime + endTime);
                        executeCurrentSql(updateLeaveSql, "OA");
                    } else if (recordEndTimeMin >= startTimeMin && recordEndTimeMin <= endTimeMin && recordStartTimeMin <= startTimeMin) {
                        //历史记录为11：10-14：15 当前申请14：10-17：15只需要补全右侧
                        //int d2_Hours=(recordEndTimeMin-startTimeMin)/60;//重复的请假时间分钟数
                        if (recordEndTimeMin >= 780) {
                            if (startTimeMin <= 705) {
                                startTimeMin = startTimeMin + 75;
                            } else if (startTimeMin > 705 && startTimeMin < 780) {
                                startTimeMin = 780;
                            } else {
                                startTimeMin = startTimeMin;
                            }
                        }
                        dHours = getDouble((double) (recordEndTimeMin - startTimeMin) / 60);
                        realHours = hours + recordHour - dHours;
                        realHours = getDouble(realHours);//请假小时数保留两位小数
                        realDays = realHours / 7.5;
                        realDays = getDouble(realDays);//请假天数保留两位小数
                        String updateLeaveSql = "update uf_AskForLeave set end_date='"+endDate+"',end_time='" + endTime + "',hours=" + realHours + ",days=" + realDays + " where requestid=" + recordRequestId + " ";
                        StringUtil.writeLog(name, updateLeaveSql);
                        StringUtil.writeLog("符合补全右侧条件:", startTime + endTime);
                        executeCurrentSql(updateLeaveSql, "OA");
                    } else if (recordStartTimeMin >= startTimeMin && recordEndTimeMin <= endTimeMin) {
                        //历史记录为11：10-14：15 当前申请08：30-17：15需要补全两侧
                        realHours = hours;
                        realDays = days;
                        dHours = recordHour;
                        String updateLeaveSql = "update uf_AskForLeave set start_date='"+startDate+"',end_date='"+endDate+"',start_time='" + startTime + "',end_time='" + endTime + "',hours=" + realHours + ",days=" + realDays + " where requestid=" + recordRequestId + " ";
                        StringUtil.writeLog(name, updateLeaveSql);
                        StringUtil.writeLog("符合补全两侧条件:", startTime + endTime);
                        executeCurrentSql(updateLeaveSql, "OA");
                    }else if(recordStartTimeMin <=startTimeMin && recordEndTimeMin >=endTimeMin){
                        StringUtil.writeLog(name,"已有记录覆盖该条申请记录");
                        dHours = hours;
                    }else {
                        dHours =0.0;
                        String insertLeaveSql = "insert into uf_AskForLeave(id,requestId,userid,depart,type,application_date,start_date,start_time,end_date,end_time,days,hours,company) values(null," + requestId + "," + userId + ",'" + depart + "'," + type + ",'" + applicationDate + "','" + startDate + "','" + startTime + "','" + endDate + "','" + endTime + "'," + days + "," + hours + ",'" + company + "')";
                        StringUtil.writeLog(name, insertLeaveSql);
                        executeCurrentSql(insertLeaveSql, "OA");
                        StringUtil.writeLog("直接插入数据:", dHours);
                    }
                }
            } else {
                String insertLeaveSql = "insert into uf_AskForLeave(id,requestId,userid,depart,type,application_date,start_date,start_time,end_date,end_time,days,hours,company) values(null," + requestId + "," + userId + ",'" + depart + "'," + type + ",'" + applicationDate + "','" + startDate + "','" + startTime + "','" + endDate + "','" + endTime + "'," + days + "," + hours + ",'" + company + "')";
                executeCurrentSql(insertLeaveSql, "OA");
                StringUtil.writeLog(name, insertLeaveSql);
            }
            StringUtil.writeLog("重复数据:", dHours);
            //如果请假类型为调休，则需要更新时间池B
            Double sum = 0.0;
            if (leaveEntity1.getType() == 8) {
                RecordSet rs2 = new RecordSet();
                //查看当前审批日期 3月份数据7月1日失效 如果申请日期在6月底 审批在7月
                SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM");
                String dateNow = sdf.format(new Date());
                //归档日期与申请日期不在同一个月 申请日期在上个月
                if (!dateNow.equals(applicationDate1.substring(0, 7))) {
                    String lastDate = dateNow.substring(0, 7) + "-01";//当月1号
                    // 查询当月1号为失效日期，失效未使用的总小时数
                    String unusedHourSql = "select sum(overtime_hours) from uf_TimePoolB where iseffective=1 and userid=" + userId + " and validate_time='" + lastDate + "' ";
                    RecordSet rs6 = new RecordSet();
                    rs6.executeSql(unusedHourSql);
                    StringUtil.writeLog(name, unusedHourSql);
                    while (rs6.next()) {
                        //获取失效未使用的总小时数
                        Double sumHours = rs6.getDouble(1);
                        StringUtil.writeLog(name, sumHours);
                        //如果失效为使用的总小时数小于本次申请的请假小时数 计算出应在有效时间内扣除的小时数
                        dHours=hours-dHours;
                        if (sumHours < dHours) {
                            dHours = dHours - sumHours;
                        }
                    }
                }
                StringUtil.writeLog(name, dHours);
                //查询当前用户有效的加班小时数 按照加班日期升序排列
                String selectSql1 = "select workdate,overtime_hours from uf_TimePoolB where iseffective=0 and userid=" + userId + " order by workdate ";
                StringUtil.writeLog(name, selectSql1);
                rs2.executeSql(selectSql1);
                Map<String, Double> map = new HashMap<String, Double>();//接收有效的加班日期及加班小时数
                while (rs2.next()) {
                    String workdate = rs2.getString("workdate");
                    Double overtimeHours = rs2.getDouble("overtime_hours");
                    sum += overtimeHours;
                    /**
                     * 各个加班工作日（升序）的加班时长
                     * 如果第一个有效时间的加班时长小于当前申请的加班时长 则将当天加班的数据赋值为空
                     * 如果到第n个加班时长小时数之和才大于当前申请的加班时长 则将前n-1个加班小时数置空 第n个加班小时数算出差值
                     */
                    Double realRelaxHours = getDouble(hours-dHours);
                    StringUtil.writeLog("需要扣除的调休小时数", realRelaxHours);
                    if (realRelaxHours > sum) {
                        map.put(workdate, 0.0);
                    } else {
                        map.put(workdate, getDouble(sum -realRelaxHours));
                        break;
                    }
                }
                StringUtil.writeLog(name, map);
                //获取加班日期的集合
                Set<String> keyList = map.keySet();
                //对加班日期按顺序处理 如果加班日期对应的加班小时数为0，则将该条记录的加班小时数更新为0 否则更新成对应集合的value值
                for (String key : keyList) {
                    Double value1 = map.get(key);
                    if (value1 == 0.0) {
                        RecordSet rs3 = new RecordSet();
                        String updateSql = "update uf_TimePoolB set overtime_hours=" + value1 + ",iseffective=1 where workdate='" + key + "' and userid='"+userId+"' ";
                        rs3.executeSql(updateSql);
                        StringUtil.writeLog(name, updateSql);
                    } else {
                        RecordSet rs4 = new RecordSet();
                        String updateSql1 = "update uf_TimePoolB set overtime_hours=" + value1 + " where workdate='" + key + "' and userid='"+userId+"'  ";
                        rs4.executeSql(updateSql1);
                        StringUtil.writeLog(name, updateSql1);
                    }
                }
            } else if (leaveEntity1.getType() == 0) {
                //如果请假类型为年假，则需要更新年假表数据
                RecordSet rs4 = new RecordSet();
                String curYear = applicationDate.substring(0, 4);
                String selectSql2 = "select used_days from uf_annual_info where userid=" + userId + " and  year= '" + curYear + "' ";
                rs4.executeSql(selectSql2);
                StringUtil.writeLog(annualName, selectSql2);
                while (rs4.next()) {
                    Double usedDays = rs4.getDouble("used_days");
                    usedDays += days;
                    String updateSql2 = "update  uf_annual_info set used_days=" + usedDays + " where userid=" + userId + " and  year= '" + curYear + "' ";
                    RecordSet rs5 = new RecordSet();
                    rs5.executeSql(updateSql2);
                    StringUtil.writeLog(annualName, updateSql2);
                }
            } else {
                StringUtil.writeLog(annualName, "当前请假类型为其他类型");
            }
        } catch (Exception e) {
            e.printStackTrace();
            StringUtil.writeLog("报错信息", e);
            return Action.FAILURE_AND_CONTINUE;
        }
        return Action.SUCCESS;
    }

    /**
     * 根据requestId查询出请假数据
     *
     * @param requestId
     * @return
     * @throws Exception
     */
    public static LeaveEntity selectKaoQinByRequestId(String requestId) throws Exception {
        RecordSet rs = new RecordSet();
        String selectSql = "select company1,depart,userid,type,application_date,start_date,start_time,end_date,end_time,days as d1,hours as h1,start_time1,end_time1,frequency from  formtable_main_615 where requestid='" + requestId + "' ";
        rs.executeSql(selectSql);
        StringUtil.writeLog(name, selectSql);
        LeaveEntity leaveEntity = new LeaveEntity();
        while (rs.next()) {
            int selectvalueCompany = rs.getInt("company1");
            StringUtil.writeLog("selectvalueCompany",selectvalueCompany);
            int selectvalueDepart = rs.getInt("depart");
            //根据selectvalue查询selectname
            String selectSql2 = "select selectname from workflow_selectitem where FIELDID=215113 and selectvalue="+selectvalueCompany+"";
            String selectSql3 = "select departmentname from hrmdepartment where id="+selectvalueDepart+"";
            String company = getName(selectSql2,"OA");
            StringUtil.writeLog("company",company);
            String depart = getName(selectSql3,"OA");
            leaveEntity.setCompany(company);
            leaveEntity.setDepart(depart);
            leaveEntity.setUserId(rs.getString("userid"));
            leaveEntity.setType(rs.getInt("type"));
            leaveEntity.setApplicationDate(rs.getString("application_date"));
            leaveEntity.setStartDate(rs.getString("start_date"));
            leaveEntity.setStartTime(rs.getString("start_time"));
            leaveEntity.setEndDate(rs.getString("end_date"));
            leaveEntity.setEndTime(rs.getString("end_time"));
            leaveEntity.setDays(rs.getDouble("d1"));
            leaveEntity.setHours(rs.getDouble("h1"));
            leaveEntity.setStartTime1(rs.getString("start_time1"));
            leaveEntity.setEndTime1(rs.getString("end_time1"));
            leaveEntity.setFrequency(rs.getInt("frequency"));
        }
        StringUtil.writeLog(name, leaveEntity.getHours());
        return leaveEntity;
    }

    /**
     * 查询该段日期范围内已经归档的请假
     */
    public static List<LeaveEntity> getRelateConditionDate(String startDate, String endDate, String userId) throws Exception {
        List<LeaveEntity> relateLeaveEntityList = new LinkedList<LeaveEntity>();
        //起始日期在当前请假开始日期，请假时间有重合
        String getRelateLeaveEntitySql = "select * from UF_ASKFORLEAVE where (start_date='" + startDate + "' or end_date='" + endDate + "') and type in (0,8)  and userid='" + userId + "' ";
        RecordSet getRelateLeaveEntityRs = new RecordSet();
        getRelateLeaveEntityRs.executeSql(getRelateLeaveEntitySql, "OA");
        StringUtil.writeLog("是否有当天记录:", getRelateLeaveEntitySql);
        while (getRelateLeaveEntityRs.next()) {
            LeaveEntity leaveEntity = new LeaveEntity();
            leaveEntity.setStartDate(getRelateLeaveEntityRs.getString("start_date"));
            leaveEntity.setStartTime(getRelateLeaveEntityRs.getString("start_time"));
            leaveEntity.setEndDate(getRelateLeaveEntityRs.getString("end_date"));
            leaveEntity.setEndTime(getRelateLeaveEntityRs.getString("end_time"));
            leaveEntity.setDays(getRelateLeaveEntityRs.getDouble("days"));
            leaveEntity.setHours(getRelateLeaveEntityRs.getDouble("hours"));
            leaveEntity.setRequestId(getRelateLeaveEntityRs.getInt("REQUESTID"));
            relateLeaveEntityList.add(leaveEntity);
        }
        return relateLeaveEntityList;
    }

    /**
     * 将时间转换成int类型
     *
     * @param curTime
     * @param index
     * @return
     */
    public static int getTimeMin(String curTime, int index) {
        int minute = Integer.parseInt(curTime.split(":")[index]);
        return minute;
    }
    public static String getName(String sql,String DateSource)throws Exception{
        RecordSet recordSet=new RecordSet();
        recordSet.executeSql(sql,DateSource);
        recordSet.next();
        String name=recordSet.getString(1);
        return name;
    }

    /**
     * 将当前sql插入表中
     */
    public static void executeCurrentSql(String sql, String dateSource) throws Exception {
        RecordSet recordSet = new RecordSet();
        recordSet.executeSql(sql, dateSource);
    }

    /**
     * 将当前double类型数据设定为两位小数
     */
    public static Double getDouble(Double n1) {
        BigDecimal bd = new BigDecimal(n1);
        Double d1 = bd.setScale(2, BigDecimal.ROUND_HALF_UP).doubleValue();
        return d1;
    }
}

