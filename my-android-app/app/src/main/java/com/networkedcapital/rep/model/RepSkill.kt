package com.networkedcapital.rep.model

// RepSkillsModel equivalent
enum class RepSkill(val displayName: String) {
    HR_SCALE("HR: Scale"),
    HR_EDUCATION("HR: Education"),
    HR_PRODUCTIVITY("HR: Productivity"),
    HR_PHYSICAL_HEALTH("HR: Physical Health"),
    HR_MENTAL_HEALTH("HR: Mental Health"),
    ENGINEERING_SOFTWARE_DESIGN("Engineering: Software Design"),
    ENGINEERING_SOFTWARE_DEV("Engineering: Software Dev"),
    ENGINEERING_HARDWARE("Engineering: Hardware"),
    ENGINEERING_CS_AND_AI("Engineering: CS and AI"),
    ENGINEERING_CIVIL("Engineering: Civil"),
    ENGINEERING_MECHANICAL("Engineering: Mechanical"),
    ENGINEERING_AIR_N_SPACE("Engineering: Air & Space"),
    ENGINEERING_MATERIALS("Engineering: Materials"),
    ENGINEERING_RND("Engineering: R&D"),
    ENGINEERING_OTHER("Engineering: Other"),
    SM_NETWORKING("Sales & Marketing: Networking"),
    SM_SALES("Sales & Marketing: Sales"),
    SM_ADVERTISING("Sales & Marketing: Advertising"),
    SM_BRANDING("Sales & Marketing: Branding"),
    SM_COMMS("Sales & Marketing: Comms"),
    GRASSROOTS_VIRTUAL_MEETINGS("Grassroots: Virtual Meetings"),
    GRASSROOTS_COORDINATION("Grassroots: Coordination"),
    GRASSROOTS_EVENT_COMMS("Grassroots: Event Comms"),
    EVENTS_PLANNING("Events: Planning"),
    EVENTS_LOGISTICS("Events: Logistics"),
    EVENTS_PROMOTION("Events: Promotion"),
    EVENTS_ITERATIVE_EVOLUTION("Events: Iterative Evolution"),
    CONTENT_GRAPHICS("Content: Graphics"),
    CONTENT_IMAGES("Content: Images"),
    CONTENT_WRITING("Content: Writing"),
    CONTENT_VIDEO_PRODUCTION("Content: Video Production"),
    CONTENT_VIDEO_EDITING("Content: Video Editing"),
    FINANCE_INTERNAL("Finance: Internal"),
    FINANCE_ACCOUNTING("Finance: Accounting"),
    FINANCE_MNA("Finance: M&A"),
    FINANCE_DEAL_STRUCTURES("Finance: Deal Structures"),
    FINANCE_INVESTING("Finance: Investing"),
    FINANCE_OPTIMIZATION("Finance: Optimization"),
    FINANCE_INCENTIVE_STRUCTURES("Finance: Incentive Structures"),
    SPIRITUAL_PRINCIPLES("Spiritual: Principles"),
    SPIRITUAL_COLLABORATION("Spiritual: Collaboration"),
    SPIRITUAL_LEADERSHIP("Spiritual: Leadership"),
    MANAGEMENT_OPTIMIZATION("Management: Optimization"),
    OTHER("Other: Other");

    companion object {
        val title = "Rep Skills"
        fun fromDisplayName(name: String): RepSkill? = values().find { it.displayName == name }
    }
}
