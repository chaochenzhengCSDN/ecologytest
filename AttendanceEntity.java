package weaver.iiot.grouptow.common.entity;

/**
 * 排班表对应的实体类
 */
public class AttendanceEntity{

    //主键id
    private int id;

    //分公司id
    private String cid;

    //日期
    private String curDate;

    //是否为工作日
    private String isWorkingDay;

    //星期几
    private String week;

    //是否是节假日
    private String isHoliday;

    //出勤状态
    private String attendanceStatus;

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getCid() {
        return cid;
    }

    public void setCid(String cid) {
        this.cid = cid;
    }

    public String getCurDate() {
        return curDate;
    }

    public void setCurDate(String curDate) {
        this.curDate = curDate;
    }

    public String getIsWorkingDay() {
        return isWorkingDay;
    }

    public void setIsWorkingDay(String isWorkingDay) {
        this.isWorkingDay = isWorkingDay;
    }

    public String getWeek() {
        return week;
    }

    public void setWeek(String week) {
        this.week = week;
    }

    public String getIsHoliday() {
        return isHoliday;
    }

    public void setIsHoliday(String isHoliday) {
        this.isHoliday = isHoliday;
    }

    public String getAttendanceStatus() {
        return attendanceStatus;
    }

    public void setAttendanceStatus(String attendanceStatus) {
        this.attendanceStatus = attendanceStatus;
    }
}