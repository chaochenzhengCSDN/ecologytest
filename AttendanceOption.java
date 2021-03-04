package weaver.iiot.grouptow.common.entity;

/**
 * 排班表对应的实体类
 */
public class AttendanceOption{

    //主键id
    private int id;

    //用户id
    private String userid;

    //日期
    private String curDate;

    //出勤状态
    private String attendancestatus;

    //开始时间
    private String starttime;

    //结束时间
    private String endtime;

    //上午结束时间
    private String morningendtime;

    //下午开始时间
    private String afternoonstarttime;

    //打卡次数
    private int frequency;

    //上午上班卡最迟打卡时间
    private String morningendtime1;

    //比较上午签到时间
    private String comparemorningin;

    //比较上午签退时间
    private String comparemorningout;

    //比较下午签到时间
    private String compareafternoonin;

    //比较下午签退时间
    private String compareafternoonout;

    public String getComparemorningin() {
        return comparemorningin;
    }

    public void setComparemorningin(String comparemorningin) {
        this.comparemorningin = comparemorningin;
    }

    public String getComparemorningout() {
        return comparemorningout;
    }

    public void setComparemorningout(String comparemorningout) {
        this.comparemorningout = comparemorningout;
    }

    public String getCompareafternoonin() {
        return compareafternoonin;
    }

    public void setCompareafternoonin(String compareafternoonin) {
        this.compareafternoonin = compareafternoonin;
    }

    public String getCompareafternoonout() {
        return compareafternoonout;
    }

    public void setCompareafternoonout(String compareafternoonout) {
        this.compareafternoonout = compareafternoonout;
    }

    public String getMorningendtime1() {
        return morningendtime1;
    }

    public void setMorningendtime1(String morningendtime1) {
        this.morningendtime1 = morningendtime1;
    }

    public int getFrequency() {
        return frequency;
    }

    public void setFrequency(int frequency) {
        this.frequency = frequency;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getUserid() {
        return userid;
    }

    public void setUserid(String userid) {
        this.userid = userid;
    }

    public String getCurDate() {
        return curDate;
    }

    public void setCurDate(String curDate) {
        this.curDate = curDate;
    }

    public String getAttendancestatus() {
        return attendancestatus;
    }

    public void setAttendancestatus(String attendancestatus) {
        this.attendancestatus = attendancestatus;
    }

    public String getStarttime() {
        return starttime;
    }

    public void setStarttime(String starttime) {
        this.starttime = starttime;
    }

    public String getEndtime() {
        return endtime;
    }

    public void setEndtime(String endtime) {
        this.endtime = endtime;
    }

    public String getMorningendtime() {
        return morningendtime;
    }

    public void setMorningendtime(String morningendtime) {
        this.morningendtime = morningendtime;
    }

    public String getAfternoonstarttime() {
        return afternoonstarttime;
    }

    public void setAfternoonstarttime(String afternoonstarttime) {
        this.afternoonstarttime = afternoonstarttime;
    }
}