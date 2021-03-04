package weaver.iiot.grouptow.common.entity;

/**
 * 排班表对应的实体类
 */
public class CurdayContion{

    //主键id
    private int id;

    //日期
    private String curDate;

    //迟到分钟数
    private Double lateTime;

    //早退分钟数
    private Double earlyTime;

    //旷工小时数
    private Double countHours;

    //实际出勤小时数
    private Double actualWorkingHours;

    //应出勤小时数
    private Double requiredWorkingHours;

    //实际出勤天数
    private Double actualWorkingDay;

    public Double getActualWorkingDay() {
        return actualWorkingDay;
    }

    public void setActualWorkingDay(Double actualWorkingDay) {
        this.actualWorkingDay = actualWorkingDay;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getCurDate() {
        return curDate;
    }

    public void setCurDate(String curDate) {
        this.curDate = curDate;
    }

    public Double getLateTime() {
        return lateTime;
    }

    public void setLateTime(Double lateTime) {
        this.lateTime = lateTime;
    }

    public Double getEarlyTime() {
        return earlyTime;
    }

    public void setEarlyTime(Double earlyTime) {
        this.earlyTime = earlyTime;
    }

    public Double getCountHours() {
        return countHours;
    }

    public void setCountHours(Double countHours) {
        this.countHours = countHours;
    }

    public Double getActualWorkingHours() {
        return actualWorkingHours;
    }

    public void setActualWorkingHours(Double actualWorkingHours) {
        this.actualWorkingHours = actualWorkingHours;
    }

    public Double getRequiredWorkingHours() {
        return requiredWorkingHours;
    }

    public void setRequiredWorkingHours(Double requiredWorkingHours) {
        this.requiredWorkingHours = requiredWorkingHours;
    }
}