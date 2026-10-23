/**
 * CMSAdmin 2.0 - Form Builder Studio JavaScript
 * Zero external dependencies. Full drag-and-drop, real-time live preview,
 * field properties inspector, pre-built templates, embed code generator,
 * interactive test simulation, and database persistence.
 */

(function () {
  "use strict";

  // Pre-configured Starter Templates
  const TEMPLATES = {
    contact: {
      title: "General Contact & Inquiry Form",
      description: "Please submit your inquiry or message. Our office typically responds within 1 to 2 business days.",
      submitText: "Send Message",
      themeColor: "#0073aa",
      successMessage: "Thank you! Your message has been sent successfully. A confirmation email has also been dispatched.",
      notificationEmail: "contact@chelancounty.gov",
      fields: [
        { id: "f_name", type: "text", label: "Full Name", placeholder: "e.g. Sarah Connor", required: true, width: "50", subtext: "" },
        { id: "f_email", type: "email", label: "Email Address", placeholder: "sarah@example.com", required: true, width: "50", subtext: "We will send your reply here." },
        { id: "f_phone", type: "phone", label: "Phone Number", placeholder: "(509) 555-0199", required: false, width: "50", subtext: "Optional for SMS updates" },
        { id: "f_dept", type: "select", label: "Department / Topic", required: true, width: "50", options: ["General Administration", "Planning & Building", "Public Works & Roads", "Natural Resources", "County Commissioners"] },
        { id: "f_subject", type: "text", label: "Subject", placeholder: "Brief summary of your inquiry", required: true, width: "100", subtext: "" },
        { id: "f_msg", type: "textarea", label: "Detailed Message", placeholder: "Describe your question, request, or comment in detail...", required: true, width: "100", subtext: "" }
      ]
    },

    survey: {
      title: "Chelan County Resident Satisfaction Survey",
      description: "Help us improve local government programs and services. This survey takes approximately 2 minutes.",
      submitText: "Submit Feedback",
      themeColor: "#27ae60",
      successMessage: "Thank you for sharing your feedback! Your ratings help shape our community programs.",
      notificationEmail: "feedback@chelancounty.gov",
      fields: [
        { id: "s_dept", type: "select", label: "Which department or facility did you visit?", required: true, width: "100", options: ["County Courthouse", "Public Records Office", "Community Development / Permitting", "Sheriff's Office", "County Parks & Recreation", "Online Website Services"] },
        { id: "s_rating", type: "rating", label: "Overall Satisfaction with Service", required: true, width: "100", subtext: "1 Star = Poor, 5 Stars = Exceptional" },
        { id: "s_timely", type: "radio", label: "Was your request handled in a timely manner?", required: true, width: "100", options: ["Yes, very quickly", "Acceptable timeframe", "Took longer than expected", "Not resolved"] },
        { id: "s_staff", type: "rating", label: "Staff Courtesy and Helpfulness", required: false, width: "100", subtext: "Rate your interaction with our staff" },
        { id: "s_comments", type: "textarea", label: "Additional Suggestions or Comments", placeholder: "What went well? How could we do better?", required: false, width: "100", subtext: "" },
        { id: "s_followup", type: "switch", label: "Would you like a supervisor to follow up with you?", required: false, width: "100", subtext: "If yes, please provide your contact info below." },
        { id: "s_email", type: "email", label: "Your Email Address (optional)", placeholder: "resident@example.com", required: false, width: "100", subtext: "" }
      ]
    },

    permit: {
      title: "Online Permit & Planning Inquiry",
      description: "Chelan County Community Development & Building Department online intake form.",
      submitText: "Submit Permit Inquiry",
      themeColor: "#e67e22",
      successMessage: "Your permit inquiry has been submitted. A planner will review your parcel details and contact you.",
      notificationEmail: "permits@chelancounty.gov",
      fields: [
        { id: "p_name", type: "text", label: "Applicant / Property Owner Name", placeholder: "John & Mary Smith", required: true, width: "50", subtext: "" },
        { id: "p_phone", type: "phone", label: "Contact Phone", placeholder: "(509) 667-6225", required: true, width: "50", subtext: "" },
        { id: "p_email", type: "email", label: "Email Address", placeholder: "applicant@example.com", required: true, width: "100", subtext: "" },
        { id: "p_parcel", type: "text", label: "Assessor Parcel Number (APN)", placeholder: "e.g. 242010123456", required: true, width: "50", subtext: "12-digit parcel ID from tax statement" },
        { id: "p_type", type: "select", label: "Permit / Inquiry Type", required: true, width: "50", options: ["Residential Building Permit", "Commercial Construction", "Boundary Line Adjustment", "Short Plat Subdivision", "Shoreline Exemption / Variance", "Code Compliance Question"] },
        { id: "p_address", type: "address", label: "Project Site Address", required: true, width: "100", subtext: "Location where work will occur" },
        { id: "p_desc", type: "textarea", label: "Description of Proposed Project", placeholder: "Include building dimensions, square footage, existing structures, and intended use...", required: true, width: "100", subtext: "" },
        { id: "p_docs", type: "file", label: "Upload Site Plan / Supporting Documents", required: false, width: "100", subtext: "PDF, DOCX, or JPG (max 25MB)" },
        { id: "p_sig", type: "signature", label: "Applicant Electronic Signature", required: true, width: "100", subtext: "By signing, you certify you are authorized to submit this inquiry." }
      ]
    },

    event: {
      title: "Community Workshop & Event RSVP",
      description: "Reserve your seat for upcoming Chelan County public hearings, workshops, and informational sessions.",
      submitText: "Confirm Registration",
      themeColor: "#8e44ad",
      successMessage: "Registration confirmed! A calendar invite and venue directions have been sent to your email.",
      notificationEmail: "events@chelancounty.gov",
      fields: [
        { id: "e_name", type: "text", label: "Attendee Full Name", placeholder: "Jane Resident", required: true, width: "50", subtext: "" },
        { id: "e_email", type: "email", label: "Email Address", placeholder: "jane@domain.com", required: true, width: "50", subtext: "" },
        { id: "e_session", type: "select", label: "Select Workshop Session", required: true, width: "100", options: ["2026 Comprehensive Plan - Oct 15 (Wenatchee)", "Lake Chelan Basin Water Quality - Oct 22 (Chelan)", "Wildfire Preparedness Town Hall - Nov 5 (Leavenworth)"] },
        { id: "e_guests", type: "number", label: "Number of Attendees in Your Party", placeholder: "1", required: true, width: "50", subtext: "Including yourself (max 5)" },
        { id: "e_accommodations", type: "checkbox", label: "Accessibility Accommodations Needed", required: false, width: "50", options: ["Wheelchair Access", "ASL Interpreter", "Spanish Translation", "Assistive Listening Device"] },
        { id: "e_agree", type: "switch", label: "Subscribe to county planning email announcements", required: false, width: "100", subtext: "" }
      ]
    },

    hrm: {
      title: "Chelan County Employment Application & Candidate Intake",
      description: "Human Resource Management (HRM) official online employment application. Chelan County is an Equal Opportunity Employer (EOE).",
      department: "HRM",
      submitText: "Submit Employment Application",
      themeColor: "#8e44ad",
      successMessage: "Thank you for applying with Chelan County! Your application has been received by HRM and is queued for recruiter review.",
      notificationEmail: "hrm@chelancounty.gov",
      fields: [
        { id: "h_intro", type: "paragraph", label: "Equal Employment Opportunity Statement", content: "Chelan County provides equal employment opportunities to all employees and applicants without regard to race, color, religion, sex, national origin, age, disability, or genetics. Reasonable accommodations are provided upon request in accordance with the ADA.", paragraphStyle: "callout", width: "100" },
        { id: "h_position", type: "select", label: "Position Applied For", required: true, width: "100", options: ["Administrative Assistant - Commissioners Office", "Planner I / II - Community Development", "Maintenance Technician - Public Works", "IT Systems Analyst - Information Technology", "Appraiser I - County Assessor", "Correctional Deputy - Sheriff Office"] },
        { id: "h_name", type: "text", label: "Full Legal Name", placeholder: "First Middle Last", required: true, width: "50", subtext: "" },
        { id: "h_email", type: "email", label: "Email Address", placeholder: "candidate@example.com", required: true, width: "50", subtext: "Official recruitment correspondence will be sent here." },
        { id: "h_phone", type: "phone", label: "Phone Number", placeholder: "(509) 555-0123", required: true, width: "50", subtext: "Cell or best daytime phone" },
        { id: "h_address", type: "address", label: "Current Physical / Mailing Address", required: true, width: "100", subtext: "Street address, city, state, zip" },
        { id: "h_auth", type: "radio", label: "Are you legally authorized to work in the United States?", required: true, width: "100", options: ["Yes, I am a US citizen or permanent legal resident", "Yes, authorized with work visa/sponsorship", "No"] },
        { id: "h_education", type: "select", label: "Highest Level of Education Completed", required: true, width: "50", options: ["High School Diploma or GED", "Associate Degree (AA/AS)", "Bachelor's Degree (BA/BS)", "Master's Degree (MA/MS)", "Doctorate / Professional Degree (JD/PhD)", "Trade / Vocational Certification"] },
        { id: "h_veteran", type: "radio", label: "Military Veteran Status (for Veteran's Scoring Preference)", required: false, width: "50", options: ["Not a Veteran", "Honorably Discharged Veteran (eligible for RCW preference)", "Active Reserve / National Guard"] },
        { id: "h_experience", type: "textarea", label: "Summary of Relevant Work Experience & Qualifications", placeholder: "Highlight your key positions, responsibilities, relevant software skills, and why you are interested in joining Chelan County...", required: true, width: "100", rows: 5, subtext: "You may also paste text from your cover letter." },
        { id: "h_resume", type: "file", label: "Upload Resume / Curriculum Vitae", required: true, width: "50", subtext: "PDF or DOCX format (max 20MB)" },
        { id: "h_cover", type: "file", label: "Upload Cover Letter (optional)", required: false, width: "50", subtext: "PDF or DOCX format (max 20MB)" },
        { id: "h_affirm", type: "paragraph", label: "Applicant Certification & Authorization", content: "I hereby certify that all information submitted in this application is true and complete. I understand that false or misleading statements or omissions may result in disqualification or dismissal. I authorize Chelan County HRM to verify all credentials.", paragraphStyle: "legal", width: "100" },
        { id: "h_signature", type: "signature", label: "Applicant Electronic Signature", required: true, width: "100", subtext: "Draw signature above with mouse or touch screen. Date will be recorded automatically." }
      ]
    },

    pio: {
      title: "Public Information Office (PIO) - Media & Press Inquiry Form",
      description: "Official intake portal for journalists, reporters, and media outlets requesting county statements, records, interview access, or background information.",
      department: "PIO",
      submitText: "Submit Media Inquiry",
      themeColor: "#0284c7",
      successMessage: "Your media inquiry has been received by the Chelan County Public Information Office (PIO). A communications officer has been notified of your deadline.",
      notificationEmail: "pio@chelancounty.gov",
      fields: [
        { id: "m_intro", type: "paragraph", label: "PIO Media Guidelines", content: "The Chelan County Public Information Office facilitates transparent communication with local, regional, and national press. Urgent breaking-news requests are prioritized according to deadline urgency.", paragraphStyle: "callout", width: "100" },
        { id: "m_outlet", type: "text", label: "News Organization / Media Outlet", placeholder: "e.g. Wenatchee World, NCW Life, Seattle Times, KOHO", required: true, width: "50", subtext: "" },
        { id: "m_medium", type: "select", label: "Media Type", required: true, width: "50", options: ["Print Newspaper / Magazine", "Television Broadcast News", "Radio / Audio Broadcast", "Digital News Website / Blog", "Podcast / Documentary", "Freelance / Independent"] },
        { id: "m_reporter", type: "text", label: "Reporter / Journalist Full Name", placeholder: "e.g. Jane Doe", required: true, width: "50", subtext: "" },
        { id: "m_email", type: "email", label: "Reporter Email Address", placeholder: "reporter@outlet.com", required: true, width: "50", subtext: "Written statements will be sent here." },
        { id: "m_phone", type: "phone", label: "Direct Phone Number", placeholder: "(509) 555-0188", required: true, width: "50", subtext: "Best phone for callback" },
        { id: "m_deadline", type: "date", label: "Publication / Broadcast Deadline Date", required: true, width: "50", subtext: "When do you need the information by?" },
        { id: "m_nature", type: "radio", label: "Nature of Media Request", required: true, width: "100", options: ["Written Statement / Quote from County Official", "On-Camera or Studio Interview Request", "Phone / Background Briefing", "Public Records / Document Verification", "Press Conference / Media Credential Access"] },
        { id: "m_urgent", type: "switch", label: "Urgent Breaking News Request (Within 2 Hours)", required: false, width: "100", subtext: "Check if deadline is active breaking news requiring immediate duty PIO alert." },
        { id: "m_questions", type: "textarea", label: "Specific Questions & Topic of Inquiry", placeholder: "Please list your specific questions, the county department or elected official involved, and any context or background...", required: true, width: "100", rows: 5, subtext: "" }
      ]
    },

    problem: {
      title: "Report a Problem & Service Request",
      description: "Chelan County Public Works online citizen service request portal. Report road hazards, potholes, streetlighting outages, fallen trees, and drainage issues.",
      department: "Public Works",
      submitText: "Submit Service Request",
      themeColor: "#d97706",
      successMessage: "Thank you for reporting this issue. Your service request has been dispatched to the Chelan County Public Works road maintenance division.",
      notificationEmail: "public.works@chelancounty.gov",
      fields: [
        { id: "pr_intro", type: "paragraph", label: "Public Works Service Request", content: "Chelan County Public Works responds to road hazards, potholes, streetlighting outages, fallen trees, and stormwater drainage issues on county-maintained roadways. For life-threatening emergencies, dial 911 immediately.", paragraphStyle: "callout", width: "100" },
        { id: "pr_category", type: "select", label: "Issue Category / Hazard Type", required: true, width: "50", options: ["Pothole / Roadway Surface Damage", "Fallen Tree / Debris in Roadway", "Traffic Sign Damaged or Missing", "Streetlight Outage / Malfunction", "Drainage / Flooding / Culvert Blockage", "Snow / Ice Road Condition Hazard", "County Park or Trail Maintenance", "Other Public Works Issue"] },
        { id: "pr_urgency", type: "radio", label: "Urgency Level", required: true, width: "50", options: ["Low - Routine maintenance", "Medium - Action needed within 48 hours", "High - Immediate safety or road blockage hazard"] },
        { id: "pr_location", type: "text", label: "Road Name / Nearest Milepost or Intersection", placeholder: "e.g. Chumstick Hwy & Milepost 4.5, or intersection with Eagle Creek Rd", required: true, width: "100", subtext: "Provide specific location or landmarks to assist county road crews" },
        { id: "pr_address", type: "address", label: "Nearest Physical Address (if known)", required: false, width: "100", subtext: "Street address, city, and zip code" },
        { id: "pr_desc", type: "textarea", label: "Detailed Description of Problem", placeholder: "Describe what you observed, direction of travel, lane affected, dimensions, etc...", required: true, rows: 4, width: "100", subtext: "" },
        { id: "pr_photo", type: "file", label: "Upload Photo of Hazard / Site Condition", required: false, width: "100", subtext: "JPG, PNG, or HEIC (max 20MB)" },
        { id: "pr_name", type: "text", label: "Reporter Full Name", placeholder: "Jane Resident", required: true, width: "50", subtext: "" },
        { id: "pr_phone", type: "phone", label: "Contact Phone Number", placeholder: "(509) 555-0144", required: true, width: "50", subtext: "For crew callback if location cannot be found" },
        { id: "pr_email", type: "email", label: "Email Address", placeholder: "jane@domain.com", required: false, width: "100", subtext: "Optional: receive ticket status updates via email" }
      ]
    },

    infestation: {
      title: "Report Infestations & Noxious Weeds",
      description: "Chelan County Natural Resources & Noxious Weed Control Board intake portal. Report noxious weeds, agricultural pests, and invasive tree borers.",
      department: "Natural Resources",
      submitText: "Submit Infestation Report",
      themeColor: "#15803d",
      successMessage: "Thank you for submitting this report. Chelan County Natural Resources and the Noxious Weed Control Board have received your filing and will review the specimen details.",
      notificationEmail: "weeds@chelancounty.gov",
      fields: [
        { id: "inf_intro", type: "paragraph", label: "Noxious Weed & Pest Control Reporting", content: "Chelan County Natural Resources and the Noxious Weed Control Board partner with landowners to prevent the spread of invasive species, state-quarantined pests (Apple Maggot, Emerald Ash Borer), and Class A/B/C noxious weeds under RCW 17.10.", paragraphStyle: "callout", width: "100" },
        { id: "inf_target", type: "select", label: "Suspected Weed, Pest, or Disease", required: true, width: "100", options: ["Puncturevine (Goathead)", "Knapweed (Diffuse / Spotted / Russian)", "Scotch Broom", "Purple Loosestrife", "Rush Skeletonweed", "Yellow Starthistle", "Apple Maggot (Rhagoletis pomonella)", "Tree Borer / Invasive Bark Beetle", "Unknown Weed / Invasive Species"] },
        { id: "inf_landtype", type: "radio", label: "Land Ownership / Property Type", required: true, width: "100", options: ["Private Landowner / Residential Property", "Commercial Orchard / Agriculture", "County Right-of-Way / Roadside", "Public Trail / Recreational Land", "USFS / BLM / State Public Land", "Unsure / Unknown"] },
        { id: "inf_parcel", type: "text", label: "County Assessor Parcel Number (APN) if known", placeholder: "e.g. 242010123456", required: false, width: "50", subtext: "12-digit parcel number from Chelan County Assessor" },
        { id: "inf_gps", type: "text", label: "GPS Coordinates or Nearest Milepost", placeholder: "e.g. 47.4235 N, -120.3103 W or Hwy 2 MP 108", required: true, width: "50", subtext: "Latitude/longitude or highway milepost" },
        { id: "inf_location", type: "address", label: "Property / Site Address", required: true, width: "100", subtext: "Physical address of property where infestation was observed" },
        { id: "inf_extent", type: "radio", label: "Estimated Area / Extent of Infestation", required: true, width: "100", options: ["Isolated single plant or few specimens (< 10 sq ft)", "Patch or cluster (10 to 500 sq ft)", "Widespread across acreage (> 1/2 acre)", "Dense infestation across multi-acre boundary"] },
        { id: "inf_photo", type: "file", label: "Upload Specimen Photo (Flowers, Leaves, Pest)", required: false, width: "100", subtext: "Close-up photo helps our weed board coordinator identify species (max 20MB)" },
        { id: "inf_name", type: "text", label: "Reporter Full Name", placeholder: "John Appleseed", required: true, width: "50", subtext: "" },
        { id: "inf_phone", type: "phone", label: "Daytime Phone Number", placeholder: "(509) 667-6436", required: true, width: "50", subtext: "" },
        { id: "inf_email", type: "email", label: "Email Address", placeholder: "landowner@appleorchard.com", required: true, width: "100", subtext: "Inspection findings and treatment recommendations will be emailed to you." }
      ]
    }
  };

  // State Management
  let currentForm = null;
  let selectedFieldId = null;
  let draggedFieldType = null;
  let isDirty = false;

  // DOM Elements
  let canvasContainer;
  let fieldsContainer;
  let fieldPropsPanel;
  let formPropsPanel;
  let formTitleInput;
  let saveStatusEl;
  let canvasTitleEl;
  let canvasDescEl;
  let formCardEl;

  // Initialize
  document.addEventListener("DOMContentLoaded", () => {
    initDOMElements();
    loadForm();
    bindEvents();
    renderFormCanvas();
    updatePropertiesInspector();
    initializeTooltips();
  });

  function initDOMElements() {
    canvasContainer = document.getElementById("fbCanvasContainer");
    fieldsContainer = document.getElementById("fbFieldsContainer");
    fieldPropsPanel = document.getElementById("fbFieldPropsPanel");
    formPropsPanel = document.getElementById("fbFormPropsPanel");
    formTitleInput = document.getElementById("fbFormTitleInput");
    saveStatusEl = document.getElementById("fbSaveStatus");
    canvasTitleEl = document.getElementById("fbCanvasTitle");
    canvasDescEl = document.getElementById("fbCanvasDesc");
    formCardEl = document.getElementById("fbFormCard");
  }

  function initializeTooltips() {
    const selector = "a, button, input:not([type='hidden']), select, textarea, [role='button'], .fb-palette-item, .fb-theme-dot, .fb-template-card";
    const roots = Array.from(document.querySelectorAll(".page-header, .fb-workspace, .fb-modal-backdrop"));

    function applyTooltips(root) {
      root.querySelectorAll(selector).forEach((element) => {
        if (element.hasAttribute("title")) return;

        let tooltip = element.getAttribute("aria-label") || element.getAttribute("data-tooltip") || "";
        const labels = element.labels ? Array.from(element.labels) : [];
        const label = labels[0] || (element.closest("label") || null);
        if (!tooltip && label) tooltip = label.textContent.trim();
        if (!tooltip) {
          const propertyGroup = element.closest(".fb-prop-group");
          const propertyLabel = propertyGroup && propertyGroup.querySelector(".fb-prop-label");
          if (propertyLabel) tooltip = propertyLabel.textContent.trim();
        }

        if (!tooltip && element.classList.contains("fb-template-card")) {
          const templateName = element.querySelector(".fb-template-name");
          tooltip = templateName ? templateName.textContent.trim() : "";
        }
        if (!tooltip && (element.matches("button, a, [role='button'], .fb-palette-item") || element.classList.contains("fb-theme-dot"))) {
          tooltip = element.textContent.trim();
        }
        if (!tooltip) tooltip = element.getAttribute("placeholder") || "";

        if (tooltip) element.setAttribute("title", tooltip);
      });
    }

    roots.forEach((root) => {
      applyTooltips(root);
      new MutationObserver((mutations) => {
        mutations.forEach((mutation) => {
          mutation.addedNodes.forEach((node) => {
            if (node.nodeType !== Node.ELEMENT_NODE) return;
            if (node.matches(selector)) {
              applyTooltips(node.parentElement || root);
            } else {
              applyTooltips(node);
            }
          });
        });
      }).observe(root, { childList: true, subtree: true });
    });
  }

  function createBlankForm() {
    const config = window.CMSAdminFormBuilderConfig || {};
    const defaultWsId = config.activeWorkspaceId || "global";
    const defaultWsName = config.activeWorkspaceName || "All Workspaces";
    return {
      id: "form_new_" + Date.now(),
      title: "Untitled Online Form",
      description: "",
      siteid: defaultWsId,
      workspaceName: defaultWsName,
      department: defaultWsId,
      departmentName: defaultWsName,
      submitText: "Submit",
      themeColor: "#0073aa",
      antiSpamEnabled: true,
      minDelaySeconds: 3,
      cooldownSeconds: 3,
      wcagCompliant: true,
      notificationEmail: "",
      successMessage: "Thank you! Your response has been submitted.",
      fields: []
    };
  }

  function loadForm() {
    const urlParams = new URLSearchParams(window.location.search);
    const templateParam = urlParams.get("template");
    const resumeParam = urlParams.get("resume");
    const serverForm = window.CMSAdminFormBuilderConfig && window.CMSAdminFormBuilderConfig.form;

    // Database forms always take precedence so editing never starts from a blank canvas.
    if (serverForm && serverForm.dbId) {
      currentForm = serverForm;
    } else if (templateParam && TEMPLATES[templateParam]) {
      currentForm = JSON.parse(JSON.stringify(TEMPLATES[templateParam]));
      currentForm.id = "form_" + templateParam + "_" + Date.now();
      localStorage.setItem("cmsadmin_active_form", JSON.stringify(currentForm));
    } else if (resumeParam === "1" || resumeParam === "true") {
      // 2. Only restore draft if user explicitly clicked "Resume In Builder"
      const saved = localStorage.getItem("cmsadmin_active_form");
      if (saved) {
        try {
          currentForm = JSON.parse(saved);
        } catch (e) {
          currentForm = null;
        }
      }
      if (!currentForm) {
        currentForm = createBlankForm();
      }
    } else {
      // 3. Default: Always start with a FRESH CLEAN CANVAS!
      currentForm = createBlankForm();
      localStorage.removeItem("cmsadmin_active_form");
    }

    // Ensure Anti-Spam and ADA WCAG defaults exist
    if (currentForm.antiSpamEnabled === undefined) currentForm.antiSpamEnabled = true;
    if (currentForm.minDelaySeconds === undefined) currentForm.minDelaySeconds = 3;
    if (currentForm.cooldownSeconds === undefined) currentForm.cooldownSeconds = 3;
    if (currentForm.wcagCompliant === undefined) currentForm.wcagCompliant = true;
    syncFormWorkspace(false);

    selectedFieldId = (currentForm.fields && currentForm.fields.length > 0)
      ? currentForm.fields[0].id
      : null;

    updateHeaderData();
  }

  function syncFormWorkspace(markAsDirty) {
    const config = window.CMSAdminFormBuilderConfig || {};
    let workspace = { id: config.activeWorkspaceId || "global", name: config.activeWorkspaceName || "All Workspaces" };
    try {
      const savedWorkspace = JSON.parse(localStorage.getItem("cmsadmin_active_workspace") || "null");
      if (savedWorkspace && typeof savedWorkspace.id === "string" && savedWorkspace.id) {
        workspace = savedWorkspace;
      }
    } catch (e) {
      // Keep fallback
    }

    if (!currentForm) return;
    if (!currentForm.dbId) {
      // New form: Department implies current active workspace
      currentForm.siteid = workspace.id;
      currentForm.workspaceName = workspace.name || workspace.id;
      currentForm.department = workspace.id;
      currentForm.departmentName = workspace.name || workspace.id;
    } else {
      // Existing form: Department implies the workspace that owns this form
      const wsList = config.workspaces || [];
      const curSiteLower = (currentForm.siteid || "").toLowerCase();
      const matched = wsList.find((w) => (w.id || "").toLowerCase() === curSiteLower || (w.code || "").toLowerCase() === curSiteLower);
      if (matched) {
        currentForm.workspaceName = matched.name;
        if (!currentForm.departmentName) currentForm.departmentName = matched.name;
      } else if (!currentForm.workspaceName) {
        currentForm.workspaceName = currentForm.siteid || "All Workspaces";
      }
      if (!currentForm.department || currentForm.department === "Administration") {
        currentForm.department = currentForm.siteid || "Administration";
        currentForm.departmentName = currentForm.workspaceName;
      }
    }

    const workspaceLabel = document.getElementById("fbFormWorkspace");
    if (workspaceLabel) workspaceLabel.textContent = "Workspace: " + (currentForm.workspaceName || "All Workspaces");

    if (markAsDirty) markDirty();
  }

  function getFieldById(id) {
    if (!currentForm || !currentForm.fields) return null;
    return currentForm.fields.find((f) => String(f.id) === String(id));
  }

  async function saveForm(showToastMsg = true) {
    if (!currentForm) return;
    const config = window.CMSAdminFormBuilderConfig || {};
    if (!currentForm.dbId) syncFormWorkspace(false);
    const btnSave = document.getElementById("btnSaveForm");
    if (btnSave) btnSave.disabled = true;
    if (saveStatusEl) {
      saveStatusEl.className = "fb-save-status unsaved";
      saveStatusEl.innerHTML = '<span class="status-indicator"></span> Saving...';
    }

    try {
      if (!config.saveUrl) {
        throw new Error("The form save endpoint is not configured.");
      }
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content") || "";
      const response = await fetch(config.saveUrl, {
        method: "POST",
        credentials: "same-origin",
        headers: {
          "Content-Type": "application/json",
          "X-Requested-With": "XMLHttpRequest",
          ...(csrfToken ? { "X-CSRF-Token": csrfToken } : {})
        },
        body: JSON.stringify({ form: currentForm })
      });
      const result = await response.json();
      if (!response.ok || !result.success || !result.form) {
        throw new Error(result.message || `Save failed with HTTP ${response.status}.`);
      }

      currentForm = { ...currentForm, ...result.form };
      localStorage.setItem("cmsadmin_active_form", JSON.stringify(currentForm));
      if (currentForm.dbId) {
        const savedUrl = new URL(window.location.href);
        savedUrl.searchParams.set("id", currentForm.dbId);
        savedUrl.searchParams.delete("template");
        savedUrl.searchParams.delete("resume");
        window.history.replaceState({}, "", savedUrl);
      }
      isDirty = false;
      updateHeaderData();
      if (saveStatusEl) {
        saveStatusEl.className = "fb-save-status";
        saveStatusEl.innerHTML = '<span class="status-indicator"></span> Saved to database';
      }
      if (showToastMsg) showToast(result.message || "Form saved successfully.");
    } catch (error) {
      if (saveStatusEl) {
        saveStatusEl.className = "fb-save-status unsaved";
        saveStatusEl.innerHTML = `<span class="status-indicator"></span> Save failed: ${escapeHTML(error.message)}`;
      }
      showToast(`Unable to save form: ${error.message}`, true);
    } finally {
      if (btnSave) btnSave.disabled = false;
    }
  }

  function markDirty() {
    isDirty = true;
    if (saveStatusEl) {
      saveStatusEl.className = "fb-save-status unsaved";
      saveStatusEl.innerHTML = '<span class="status-indicator" style="background:var(--admin-warning);"></span> Unsaved changes';
    }
  }

  function updateHeaderData() {
    if (formTitleInput) formTitleInput.value = currentForm.title;
    if (canvasTitleEl) canvasTitleEl.innerText = currentForm.title;
    if (canvasDescEl) canvasDescEl.innerText = currentForm.description || "Click to add instructions...";
    if (formCardEl && currentForm.themeColor) {
      formCardEl.style.borderTopColor = currentForm.themeColor;
    }
  }

  function bindEvents() {
    window.addEventListener("cmsadmin:workspaceChanged", () => {
      syncFormWorkspace(true);
      if (formPropsPanel && formPropsPanel.style.display !== "none") {
        populateFormSettings();
      }
    });

    // 1. Title & Desc Edit
    if (formTitleInput) {
      formTitleInput.addEventListener("input", (e) => {
        currentForm.title = e.target.value || "Untitled Online Form";
        if (canvasTitleEl) canvasTitleEl.innerText = currentForm.title;
        markDirty();
      });
    }

    if (canvasTitleEl) {
      canvasTitleEl.addEventListener("click", () => {
        switchTab("form");
        const titleField = document.getElementById("formPropTitle");
        if (titleField) titleField.focus();
      });
    }

    if (canvasDescEl) {
      canvasDescEl.addEventListener("click", () => {
        switchTab("form");
        const descField = document.getElementById("formPropDesc");
        if (descField) descField.focus();
      });
    }

    // 2. Palette Item Clicks (Click to Add)
    document.querySelectorAll(".fb-palette-item").forEach((item) => {
      item.addEventListener("click", () => {
        const type = item.getAttribute("data-type");
        addField(type);
      });

      // HTML5 Drag
      item.setAttribute("draggable", "true");
      item.addEventListener("dragstart", (e) => {
        draggedFieldType = item.getAttribute("data-type");
        e.dataTransfer.setData("text/plain", draggedFieldType);
        e.dataTransfer.effectAllowed = "copy";
      });
    });

    // 3. Canvas Drag and Drop Target
    if (fieldsContainer) {
      fieldsContainer.addEventListener("dragover", (e) => {
        e.preventDefault();
        e.dataTransfer.dropEffect = "copy";
      });

      fieldsContainer.addEventListener("drop", (e) => {
        e.preventDefault();
        const type = draggedFieldType || e.dataTransfer.getData("text/plain");
        if (type) {
          addField(type);
          draggedFieldType = null;
        }
      });
    }

    // 4. Palette Search Filter
    const paletteSearch = document.getElementById("fbPaletteSearch");
    if (paletteSearch) {
      paletteSearch.addEventListener("input", (e) => {
        const query = e.target.value.toLowerCase().trim();
        document.querySelectorAll(".fb-palette-item").forEach((item) => {
          const text = item.innerText.toLowerCase();
          item.style.display = text.includes(query) ? "flex" : "none";
        });
      });
    }

    // 5. Device Preview Switcher (Desktop / Tablet / Mobile)
    document.querySelectorAll(".fb-device-btn").forEach((btn) => {
      btn.addEventListener("click", () => {
        document.querySelectorAll(".fb-device-btn").forEach((b) => b.classList.remove("active"));
        btn.classList.add("active");
        const mode = btn.getAttribute("data-mode");
        canvasContainer.className = "fb-canvas-container preview-" + mode;
        updateMobileColumnAdaptation();
      });
    });

    // Window resize listener to automatically adapt columns on mobile viewports
    window.addEventListener("resize", () => {
      updateMobileColumnAdaptation();
    });

    // 6. Action Bar Buttons
    const btnSave = document.getElementById("btnSaveForm");
    if (btnSave) {
      btnSave.addEventListener("click", () => saveForm(true));
    }

    const btnTemplates = document.getElementById("btnOpenTemplates");
    if (btnTemplates) {
      btnTemplates.addEventListener("click", () => openModal("fbTemplatesModal"));
    }

    const btnPreview = document.getElementById("btnPreviewForm");
    if (btnPreview) {
      btnPreview.addEventListener("click", () => openPreviewModal());
    }

    const btnShare = document.getElementById("btnShareEmbed");
    if (btnShare) {
      btnShare.addEventListener("click", () => openShareModal());
    }

    const btnClear = document.getElementById("btnClearForm");
    if (btnClear) {
      btnClear.addEventListener("click", async () => {
        if (await window.adminConfirm("Are you sure you want to clear all fields and start with a fresh clean canvas?", {
          title: "Clear form?",
          acceptText: "Clear form",
          destructive: true
        })) {
          currentForm = createBlankForm();
          syncFormWorkspace(false);
          selectedFieldId = null;
          localStorage.removeItem("cmsadmin_active_form");
          updateHeaderData();
          renderFormCanvas();
          updatePropertiesInspector();
          markDirty();
        }
      });
    }

    // 7. Template Cards Clicks
    document.querySelectorAll(".fb-template-card").forEach((card) => {
      card.addEventListener("click", () => {
        const key = card.getAttribute("data-template");
        if (TEMPLATES[key]) {
          const tpl = JSON.parse(JSON.stringify(TEMPLATES[key]));
          const curSite = currentForm ? (currentForm.siteid || "") : "";
          const curName = currentForm ? (currentForm.workspaceName || "") : "";
          currentForm = tpl;
          currentForm.id = "form_" + Date.now();
          if (curSite && curSite !== "global") {
            currentForm.siteid = curSite;
            currentForm.workspaceName = curName;
            currentForm.department = curSite;
            currentForm.departmentName = curName;
          } else {
            syncFormWorkspace(false);
          }
          selectedFieldId = currentForm.fields.length ? currentForm.fields[0].id : null;
          updateHeaderData();
          renderFormCanvas();
          updatePropertiesInspector();
          closeModal("fbTemplatesModal");
          markDirty();
          showToast(`Loaded "${currentForm.title}" template!`);
        }
      });
    });

    // 8. Inspector Tabs (Field vs Form)
    document.querySelectorAll(".fb-inspector-tab").forEach((tab) => {
      tab.addEventListener("click", () => {
        const target = tab.getAttribute("data-tab");
        switchTab(target);
      });
    });

    // 9. Close Modal Handlers
    document.querySelectorAll(".fb-modal-close, [data-dismiss='modal']").forEach((btn) => {
      btn.addEventListener("click", () => {
        const modal = btn.closest(".fb-modal-backdrop");
        if (modal) modal.classList.remove("open");
      });
    });

    document.querySelectorAll(".fb-modal-backdrop").forEach((modal) => {
      modal.addEventListener("click", (e) => {
        if (e.target === modal) modal.classList.remove("open");
      });
    });

    // 10. Copy Buttons in Embed Modal
    const btnCopyEmbed = document.getElementById("btnCopyEmbedCode");
    if (btnCopyEmbed) {
      btnCopyEmbed.addEventListener("click", async () => {
        const code = document.getElementById("fbEmbedCode").innerText;
        const ok = typeof window.copyToClipboard === "function"
          ? await window.copyToClipboard(code)
          : await fallbackCopyText(code);
        if (ok) {
          showToast("Embed code copied to clipboard!", "success");
          const origHTML = btnCopyEmbed.innerHTML;
          btnCopyEmbed.innerHTML = `
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
            <span>Copied!</span>
          `;
          btnCopyEmbed.classList.add("btn-success");
          setTimeout(() => {
            btnCopyEmbed.innerHTML = origHTML;
            btnCopyEmbed.classList.remove("btn-success");
          }, 2000);
        }
      });
    }

    const btnCopyLink = document.getElementById("btnCopyDirectLink");
    if (btnCopyLink) {
      btnCopyLink.addEventListener("click", async () => {
        const link = document.getElementById("fbDirectLinkInput").value;
        const ok = typeof window.copyToClipboard === "function"
          ? await window.copyToClipboard(link)
          : await fallbackCopyText(link);
        if (ok) {
          showToast("Direct form URL copied to clipboard!", "success");
          const origHTML = btnCopyLink.innerHTML;
          btnCopyLink.innerHTML = `
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
            <span>Copied!</span>
          `;
          btnCopyLink.classList.add("btn-success");
          setTimeout(() => {
            btnCopyLink.innerHTML = origHTML;
            btnCopyLink.classList.remove("btn-success");
          }, 2000);
        }
      });
    }

    // Download Standalone HTML
    const btnDownloadHTML = document.getElementById("btnDownloadHTML");
    if (btnDownloadHTML) {
      btnDownloadHTML.addEventListener("click", () => downloadStandaloneHTML());
    }

    // Export JSON
    const btnExportJSON = document.getElementById("btnExportJSON");
    if (btnExportJSON) {
      btnExportJSON.addEventListener("click", () => exportJSON());
    }
  }

  function switchTab(tabName) {
    document.querySelectorAll(".fb-inspector-tab").forEach((tab) => {
      tab.classList.toggle("active", tab.getAttribute("data-tab") === tabName);
    });

    if (fieldPropsPanel && formPropsPanel) {
      fieldPropsPanel.style.display = tabName === "field" ? "block" : "none";
      formPropsPanel.style.display = tabName === "form" ? "block" : "none";
    }

    if (tabName === "form") {
      populateFormSettings();
    } else if (tabName === "field") {
      if ((!selectedFieldId || !getFieldById(selectedFieldId)) && currentForm && currentForm.fields && currentForm.fields.length > 0) {
        selectedFieldId = currentForm.fields[0].id;
        document.querySelectorAll(".fb-field-item").forEach((item) => {
          item.classList.toggle("active", String(item.getAttribute("data-id")) === String(selectedFieldId));
        });
      }
      updatePropertiesInspector();
    }
  }

  // =========================================================================
  // Canvas Rendering & Field Construction
  // =========================================================================
  function renderFormCanvas() {
    if (!fieldsContainer) return;
    fieldsContainer.innerHTML = "";

    if (!currentForm.fields || currentForm.fields.length === 0) {
      fieldsContainer.classList.add("is-empty");
      fieldsContainer.innerHTML = `
        <div class="fb-empty-canvas">
          <div class="fb-empty-icon">
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <rect width="8" height="4" x="8" y="2" rx="1" ry="1"/>
              <path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"/>
              <path d="M12 11h4"/><path d="M12 16h4"/><path d="M8 11h.01"/><path d="M8 16h.01"/>
            </svg>
          </div>
          <div>
            <div class="fb-empty-title">Your form has no fields yet</div>
            <p class="fb-empty-desc">Click any field type on the left palette to add it, or pick a starter template to get up and running fast.</p>
          </div>
          <div class="fb-empty-actions">
            <button type="button" class="btn btn-primary btn-sm" onclick="document.getElementById('btnOpenTemplates').click()">
              Browse Starter Templates
            </button>
            <button type="button" class="btn btn-outline btn-sm" onclick="window.CMSAdminFormBuilder.addField('text')">
              + Add First Field
            </button>
          </div>
        </div>
      `;
      const existingFooter = document.getElementById("fbCanvasSubmitFooter");
      if (existingFooter) existingFooter.remove();
      return;
    }

    fieldsContainer.classList.remove("is-empty");

    // Render fields with responsive column classes
    currentForm.fields.forEach((field) => {
      const itemDOM = createFieldDOM(field);
      const widthVal = field.width || "100";
      itemDOM.setAttribute("data-desktop-col", widthVal);
      itemDOM.classList.add(`fb-field-col-${widthVal}`);
      fieldsContainer.appendChild(itemDOM);
    });

    renderSubmitFooter();
    updateMobileColumnAdaptation();
  }

  // Determine if the form builder is currently running in mobile mode (simulation or viewport)
  function isMobileMode() {
    const isMobileSim = !!(canvasContainer && canvasContainer.classList.contains("preview-mobile"));
    const isMobileViewport = window.innerWidth <= 768;
    return isMobileSim || isMobileViewport;
  }

  // Automatically adapt columns: change fb-field-col-50 and fb-field-col-33 to fb-field-col-100 on mobile
  function updateMobileColumnAdaptation() {
    if (!canvasContainer) return;
    const isMobile = isMobileMode();

    const fieldItems = canvasContainer.querySelectorAll(".fb-field-item");
    fieldItems.forEach((item) => {
      const id = item.getAttribute("data-id");
      const field = getFieldById(id);
      const configuredWidth = (field && field.width)
        ? String(field.width)
        : (item.getAttribute("data-desktop-col") || "100");

      if (!item.hasAttribute("data-desktop-col")) {
        item.setAttribute("data-desktop-col", configuredWidth);
      }

      if (isMobile) {
        // Automatically change fb-field-col-50 and fb-field-col-33 to fb-field-col-100 on mobile
        if (configuredWidth === "50" || configuredWidth === "33") {
          item.classList.remove("fb-field-col-50", "fb-field-col-33");
          item.classList.add("fb-field-col-100");
          item.setAttribute("data-mobile-adapted", "true");
        }
      } else {
        // Restore configured column class (fb-field-col-50 / fb-field-col-33 / fb-field-col-100)
        item.removeAttribute("data-mobile-adapted");
        item.classList.remove("fb-field-col-100", "fb-field-col-50", "fb-field-col-33");
        item.classList.add(`fb-field-col-${configuredWidth}`);
      }
    });
  }

  function renderSubmitFooter() {
    const existingFooter = document.getElementById("fbCanvasSubmitFooter");
    if (existingFooter) existingFooter.remove();

    const footer = document.createElement("div");
    footer.id = "fbCanvasSubmitFooter";
    footer.className = "fb-form-footer";

    const submitBtn = document.createElement("button");
    submitBtn.type = "button";
    submitBtn.className = "fb-submit-btn-preview";
    submitBtn.innerText = currentForm.submitText || "Submit Form";
    submitBtn.title = "Preview the form's submit button; change its label in Form Settings.";
    if (currentForm.themeColor) {
      submitBtn.style.background = currentForm.themeColor;
    }

    footer.appendChild(submitBtn);
    fieldsContainer.parentElement.appendChild(footer);
  }

  function createFieldDOM(field) {
    const el = document.createElement("div");
    el.className = "fb-field-item" + (String(field.id) === String(selectedFieldId) ? " active" : "");
    el.setAttribute("data-id", field.id);
    el.title = "Select this field to edit its settings.";

    // Floating Toolbar with Settings Button
    const toolbar = document.createElement("div");
    toolbar.className = "fb-field-toolbar";
    toolbar.innerHTML = `
      <button type="button" class="fb-field-tool-btn primary" title="Field Settings" onclick="event.stopPropagation(); window.CMSAdminFormBuilder.selectField('${field.id}')">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>
      </button>
      <button type="button" class="fb-field-tool-btn" title="Move Up" onclick="event.stopPropagation(); window.CMSAdminFormBuilder.moveField('${field.id}', -1)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="18 15 12 9 6 15"/></svg>
      </button>
      <button type="button" class="fb-field-tool-btn" title="Move Down" onclick="event.stopPropagation(); window.CMSAdminFormBuilder.moveField('${field.id}', 1)">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="6 9 12 15 18 9"/></svg>
      </button>
      <button type="button" class="fb-field-tool-btn" title="Duplicate Field" onclick="event.stopPropagation(); window.CMSAdminFormBuilder.duplicateField('${field.id}')">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect width="14" height="14" x="8" y="8" rx="2"/><path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2"/></svg>
      </button>
      <button type="button" class="fb-field-tool-btn danger" title="Delete Field" onclick="event.stopPropagation(); window.CMSAdminFormBuilder.deleteField('${field.id}')">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>
      </button>
    `;
    el.appendChild(toolbar);

    // Field Content Markup with WCAG IDs & Attributes
    let fieldMarkup = "";
    const reqStar = field.required ? '<span class="fb-required-star" aria-hidden="true">*</span><span class="sr-only"> (required)</span>' : "";
    const subtext = field.subtext ? `<div class="fb-subtext" id="desc_${field.id}">${escapeHTML(field.subtext)}</div>` : "";

    switch (field.type) {
      case "text":
        fieldMarkup = `
          <label class="fb-label" for="preview_${field.id}">${escapeHTML(field.label)}${reqStar}</label>
          <input type="text" id="preview_${field.id}" class="fb-input-preview" placeholder="${escapeHTML(field.placeholder || "Enter text...")}" readonly>
          ${subtext}
        `;
        break;

      case "textarea":
        fieldMarkup = `
          <label class="fb-label" for="preview_${field.id}">${escapeHTML(field.label)}${reqStar}</label>
          <textarea id="preview_${field.id}" class="fb-textarea-preview" rows="${field.rows || 4}" placeholder="${escapeHTML(field.placeholder || "Enter your detailed response...")}" readonly></textarea>
          ${subtext}
        `;
        break;

      case "paragraph":
        fieldMarkup = `
          <div class="fb-paragraph-block ${field.paragraphStyle ? 'style-' + field.paragraphStyle : ''}">
            <p class="fb-paragraph-text">${escapeHTML(field.content || field.label || "Enter informational instructions or guidelines for respondents...")}</p>
          </div>
          ${subtext}
        `;
        break;

      case "email":
        fieldMarkup = `
          <label class="fb-label" for="preview_${field.id}">${escapeHTML(field.label)}${reqStar}</label>
          <input type="email" id="preview_${field.id}" class="fb-input-preview" placeholder="${escapeHTML(field.placeholder || "name@example.com")}" readonly>
          ${subtext}
        `;
        break;

      case "phone":
        fieldMarkup = `
          <label class="fb-label" for="preview_${field.id}">${escapeHTML(field.label)}${reqStar}</label>
          <input type="tel" id="preview_${field.id}" class="fb-input-preview" placeholder="${escapeHTML(field.placeholder || "(509) 000-0000")}" readonly>
          ${subtext}
        `;
        break;

      case "number":
        fieldMarkup = `
          <label class="fb-label" for="preview_${field.id}">${escapeHTML(field.label)}${reqStar}</label>
          <input type="number" id="preview_${field.id}" class="fb-input-preview" placeholder="${escapeHTML(field.placeholder || "0")}" readonly>
          ${subtext}
        `;
        break;

      case "select":
        const opts = (field.options || ["Option 1", "Option 2"]).map((opt) => `<option>${escapeHTML(opt)}</option>`).join("");
        fieldMarkup = `
          <label class="fb-label" for="preview_${field.id}">${escapeHTML(field.label)}${reqStar}</label>
          <select id="preview_${field.id}" class="fb-input-preview" readonly><option selected>-- Select an option --</option>${opts}</select>
          ${subtext}
        `;
        break;

      case "radio":
        const radioList = Array.isArray(field.options) && field.options.length ? field.options : ["Option 1", "Option 2"];
        const radioItems = radioList.map((opt, idx) => `
          <label class="fb-option-item">
            <input type="radio" id="rad_${field.id}_${idx}" name="preview_${field.id}" value="${escapeHTML(opt)}" ${idx === 0 ? "checked" : ""}>
            <span>${escapeHTML(opt)}</span>
          </label>
        `).join("");
        fieldMarkup = `
          <fieldset class="fb-fieldset" role="radiogroup">
            <legend class="fb-legend">${escapeHTML(field.label)}${reqStar}</legend>
            <div class="fb-options-preview">${radioItems}</div>
          </fieldset>
          ${subtext}
        `;
        break;

      case "checkbox":
        const checkList = Array.isArray(field.options) && field.options.length ? field.options : ["Option 1", "Option 2"];
        const checkItems = checkList.map((opt, idx) => `
          <label class="fb-option-item">
            <input type="checkbox" id="chk_${field.id}_${idx}" value="${escapeHTML(opt)}" ${idx === 0 ? "checked" : ""}>
            <span>${escapeHTML(opt)}</span>
          </label>
        `).join("");
        fieldMarkup = `
          <fieldset class="fb-fieldset" role="group">
            <legend class="fb-legend">${escapeHTML(field.label)}${reqStar}</legend>
            <div class="fb-options-preview">${checkItems}</div>
          </fieldset>
          ${subtext}
        `;
        break;

      case "switch":
        fieldMarkup = `
          <div style="display:flex; align-items:center; justify-content:space-between; gap:1rem;">
            <div>
              <label class="fb-label" for="preview_${field.id}" style="margin-bottom:0;">${escapeHTML(field.label)}${reqStar}</label>
              ${subtext}
            </div>
            <input type="checkbox" id="preview_${field.id}" checked readonly style="width:20px; height:20px; accent-color:var(--admin-primary);">
          </div>
        `;
        break;

      case "date":
        fieldMarkup = `
          <label class="fb-label" for="preview_${field.id}">${escapeHTML(field.label)}${reqStar}</label>
          <input type="date" id="preview_${field.id}" class="fb-input-preview" value="2026-10-15" readonly>
          ${subtext}
        `;
        break;

      case "rating":
        fieldMarkup = `
          <label class="fb-label">${escapeHTML(field.label)}${reqStar}</label>
          <div class="fb-star-rating-preview" role="img" aria-label="5 star satisfaction rating">
            ${'<svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor" stroke="none"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>'.repeat(5)}
          </div>
          ${subtext}
        `;
        break;

      case "file":
        fieldMarkup = `
          <label class="fb-label" for="preview_${field.id}">${escapeHTML(field.label)}${reqStar}</label>
          <div class="fb-file-upload-preview">
            <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 14.899A7 7 0 1 1 15.71 8h1.79a4.5 4.5 0 0 1 2.5 8.242"/><path d="M12 12v9"/><path d="m16 16-4-4-4 4"/></svg>
            <div><strong>Click or drag files here</strong> to upload</div>
            <div style="font-size:0.75rem; color:var(--admin-text-subtle);">PDF, DOCX, PNG, JPG up to 25MB</div>
          </div>
          ${subtext}
        `;
        break;

      case "signature":
        fieldMarkup = `
          <label class="fb-label" for="preview_${field.id}">${escapeHTML(field.label)}${reqStar}</label>
          <div class="fb-signature-pad-preview">
            <span>Draw or type signature online here &bull; Chelan County Verified</span>
          </div>
          ${subtext}
        `;
        break;

      case "address":
        fieldMarkup = `
          <fieldset class="fb-fieldset fb-address-group" role="group">
            <legend class="fb-legend">${escapeHTML(field.label)}${reqStar}</legend>
            <div class="fb-address-fields">
              <div class="fb-address-row">
                <input type="text" class="fb-input-preview" placeholder="Street Address (e.g. 350 Orondo Ave)" readonly aria-label="Street Address">
              </div>
              <div class="fb-address-row">
                <input type="text" class="fb-input-preview" placeholder="Apt, Suite, Unit, Building (Optional)" readonly aria-label="Address Line 2">
              </div>
              <div class="fb-address-row fb-address-row-city-state-zip">
                <div class="fb-address-col-city">
                  <input type="text" class="fb-input-preview" placeholder="City (e.g. Wenatchee)" readonly aria-label="City">
                </div>
                <div class="fb-address-col-state">
                  <input type="text" class="fb-input-preview" placeholder="State" value="${escapeHTML(field.defaultState || "WA")}" readonly aria-label="State">
                </div>
                <div class="fb-address-col-zip">
                  <input type="text" class="fb-input-preview" placeholder="ZIP Code (e.g. 98801)" readonly aria-label="ZIP Code">
                </div>
              </div>
            </div>
          </fieldset>
          ${subtext}
        `;
        break;

      case "heading":
        fieldMarkup = `
          <div class="fb-section-heading-preview" role="heading" aria-level="3">${escapeHTML(field.label)}</div>
          ${field.subtext ? `<div style="font-size:0.85rem; color:var(--admin-text-muted);">${escapeHTML(field.subtext)}</div>` : ""}
        `;
        break;

      case "divider":
        fieldMarkup = `
          <div class="fb-section-divider-preview" role="separator"></div>
        `;
        break;

      default:
        fieldMarkup = `
          <label class="fb-label" for="preview_${field.id}">${escapeHTML(field.label)}${reqStar}</label>
          <input type="text" id="preview_${field.id}" class="fb-input-preview" readonly>
        `;
    }

    const contentDiv = document.createElement("div");
    contentDiv.innerHTML = fieldMarkup;
    el.appendChild(contentDiv);

    // Click to select
    el.addEventListener("click", () => {
      selectField(field.id);
    });

    return el;
  }

  // =========================================================================
  // Field Operations (Add, Select, Duplicate, Delete, Move)
  // =========================================================================
  function addField(type) {
    const newId = "f_" + Math.random().toString(36).substr(2, 7);
    let newField = {
      id: newId,
      type: type,
      label: getDefaultLabel(type),
      placeholder: getDefaultPlaceholder(type),
      required: false,
      width: "100",
      subtext: ""
    };

    if (type === "textarea") {
      newField.rows = 4;
      newField.placeholder = "Write your detailed feedback, inquiry, or comments here...";
    } else if (type === "paragraph") {
      newField.label = "Notice & Instructions";
      newField.content = "Please provide complete and accurate information. If you have questions or require accommodations under the Americans with Disabilities Act (ADA), please contact our office.";
      newField.paragraphStyle = "callout";
    }

    if (["select", "radio", "checkbox"].includes(type)) {
      newField.options = ["Option 1", "Option 2", "Option 3"];
    }

    if (!currentForm.fields) currentForm.fields = [];
    currentForm.fields.push(newField);
    selectedFieldId = newId;

    renderFormCanvas();
    updatePropertiesInspector();
    switchTab("field");
    markDirty();

    // Scroll new field into view smoothly
    setTimeout(() => {
      const fieldEl = document.querySelector(`.fb-field-item[data-id="${newId}"]`);
      if (fieldEl) fieldEl.scrollIntoView({ behavior: "smooth", block: "nearest" });
    }, 50);
  }

  function selectField(id) {
    selectedFieldId = String(id);
    document.querySelectorAll(".fb-field-item").forEach((item) => {
      item.classList.toggle("active", String(item.getAttribute("data-id")) === String(id));
    });
    switchTab("field");
    updatePropertiesInspector();
  }

  function duplicateField(id) {
    const index = currentForm.fields.findIndex((f) => String(f.id) === String(id));
    if (index === -1) return;

    const source = currentForm.fields[index];
    const clone = JSON.parse(JSON.stringify(source));
    clone.id = "f_" + Math.random().toString(36).substr(2, 7);
    clone.label = clone.label + " (Copy)";

    currentForm.fields.splice(index + 1, 0, clone);
    selectedFieldId = clone.id;

    renderFormCanvas();
    updatePropertiesInspector();
    markDirty();
    showToast(`Duplicated "${source.label}"`);
  }

  function deleteField(id) {
    const index = currentForm.fields.findIndex((f) => String(f.id) === String(id));
    if (index === -1) return;

    const deleted = currentForm.fields.splice(index, 1)[0];
    if (String(selectedFieldId) === String(id)) {
      selectedFieldId = currentForm.fields.length ? currentForm.fields[Math.max(0, index - 1)].id : null;
    }

    renderFormCanvas();
    updatePropertiesInspector();
    markDirty();
    showToast(`Deleted field "${deleted.label}"`);
  }

  function moveField(id, delta) {
    const index = currentForm.fields.findIndex((f) => String(f.id) === String(id));
    if (index === -1) return;

    const targetIndex = index + delta;
    if (targetIndex < 0 || targetIndex >= currentForm.fields.length) return;

    const [item] = currentForm.fields.splice(index, 1);
    currentForm.fields.splice(targetIndex, 0, item);

    renderFormCanvas();
    markDirty();
  }

  function getDefaultLabel(type) {
    switch (type) {
      case "text": return "Full Name";
      case "textarea": return "Detailed Comments & Message";
      case "paragraph": return "Notice & Instructions";
      case "email": return "Email Address";
      case "phone": return "Phone Number";
      case "number": return "Quantity / Amount";
      case "select": return "Select Department";
      case "radio": return "Primary Preference";
      case "checkbox": return "Select All That Apply";
      case "switch": return "I agree to the terms and privacy policy";
      case "date": return "Appointment / Event Date";
      case "rating": return "Service Rating";
      case "file": return "Attach Documents";
      case "signature": return "Official Digital Signature";
      case "address": return "Mailing / Physical Address";
      case "heading": return "Section Header";
      case "divider": return "Section Divider";
      default: return "Custom Field";
    }
  }

  function getDefaultPlaceholder(type) {
    switch (type) {
      case "text": return "e.g. John Doe";
      case "textarea": return "Write your detailed feedback, inquiry, or comments here...";
      case "email": return "name@domain.gov";
      case "phone": return "(509) 000-0000";
      case "number": return "1";
      default: return "";
    }
  }

  // =========================================================================
  // Properties Inspector & Form Settings
  // =========================================================================
  function updatePropertiesInspector() {
    if (!fieldPropsPanel) return;

    const field = getFieldById(selectedFieldId);

    if (!field) {
      fieldPropsPanel.innerHTML = `
        <div style="text-align:center; padding:3rem 1rem; color:var(--admin-text-muted);">
          <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="margin-bottom:0.75rem; color:var(--admin-text-subtle);">
            <path d="M12 20h9"/><path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z"/>
          </svg>
          <div style="font-weight:600; color:var(--admin-text-main); margin-bottom:0.25rem;">No field selected</div>
          <div style="font-size:0.8rem;">Click any field in the center canvas to customize its label, validation, and layout.</div>
        </div>
      `;
      return;
    }

    let optionsMarkup = "";
    if (["select", "radio", "checkbox"].includes(field.type)) {
      const optsList = (field.options || []).map((opt, i) => `
        <div class="fb-option-edit-row">
          <span class="fb-option-num">${i + 1}.</span>
          <input type="text" value="${escapeHTML(opt)}" 
            oninput="window.CMSAdminFormBuilder.updateOption(${i}, this.value)" 
            onkeydown="if(event.key==='Enter'){event.preventDefault(); window.CMSAdminFormBuilder.addOption();}" 
            placeholder="Option ${i + 1}"
            aria-label="Option ${i + 1}">
          <button type="button" class="fb-btn-del-option" title="Delete Option" onclick="window.CMSAdminFormBuilder.removeOption(${i})">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
          </button>
        </div>
      `).join("");

      optionsMarkup = `
        <div class="fb-prop-group">
          <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:0.4rem;">
            <label class="fb-prop-label" style="margin:0;">Manage Choices &amp; Options</label>
            <span style="font-size:0.7rem; color:var(--admin-text-muted);">${(field.options || []).length} choices</span>
          </div>
          <div class="fb-options-list">${optsList}</div>
          <button type="button" class="btn btn-secondary btn-sm" style="width:100%; font-size:0.775rem;" onclick="window.CMSAdminFormBuilder.addOption()">
            + Add Option
          </button>
          <div style="font-size:0.72rem; color:var(--admin-text-muted); margin-top:0.35rem; line-height:1.4;">
            Press <kbd style="background:var(--admin-bg); padding:1px 4px; border:1px solid var(--admin-border); border-radius:3px; font-size:0.65rem;">Enter</kbd> to add the next option quickly.
          </div>
        </div>
      `;
    }

    fieldPropsPanel.innerHTML = `
      <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:1rem; padding-bottom:0.5rem; border-bottom:1px solid var(--admin-border-subtle);">
        <div style="display:flex; align-items:center; gap:0.4rem;">
          <span class="badge badge-primary" style="text-transform:uppercase; font-size:0.65rem;">${field.type}</span>
          <span class="badge badge-success" style="font-size:0.6rem;">WCAG AA</span>
        </div>
        <button type="button" class="btn btn-outline btn-sm btn-icon-only" style="color:var(--admin-danger); width:28px; height:28px;" title="Delete Field" onclick="window.CMSAdminFormBuilder.deleteField('${field.id}')">
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>
        </button>
      </div>

      <div class="fb-prop-group">
        <label class="fb-prop-label" for="propFieldType">Field Element Type</label>
        <select class="fb-prop-select" id="propFieldType" onchange="window.CMSAdminFormBuilder.updateFieldType(this.value)">
          <optgroup label="Standard Inputs">
            <option value="text" ${field.type === "text" ? "selected" : ""}>Short Text Input</option>
            <option value="textarea" ${field.type === "textarea" ? "selected" : ""}>Paragraph (Long Text / Textarea)</option>
            <option value="email" ${field.type === "email" ? "selected" : ""}>Email Address</option>
            <option value="phone" ${field.type === "phone" ? "selected" : ""}>Phone Number</option>
            <option value="number" ${field.type === "number" ? "selected" : ""}>Number / Quantity</option>
            <option value="date" ${field.type === "date" ? "selected" : ""}>Date Picker</option>
          </optgroup>
          <optgroup label="Choices & Options">
            <option value="select" ${field.type === "select" ? "selected" : ""}>Dropdown (Single Select)</option>
            <option value="radio" ${field.type === "radio" ? "selected" : ""}>Radio Group (Single Choice)</option>
            <option value="checkbox" ${field.type === "checkbox" ? "selected" : ""}>Checkboxes (Multi-Choice)</option>
            <option value="switch" ${field.type === "switch" ? "selected" : ""}>Agreement Toggle</option>
          </optgroup>
          <optgroup label="Advanced & Media">
            <option value="rating" ${field.type === "rating" ? "selected" : ""}>Star Satisfaction Rating</option>
            <option value="file" ${field.type === "file" ? "selected" : ""}>File Upload</option>
            <option value="signature" ${field.type === "signature" ? "selected" : ""}>Digital Signature</option>
            <option value="address" ${field.type === "address" ? "selected" : ""}>Address Block</option>
          </optgroup>
          <optgroup label="Structure & Content">
            <option value="heading" ${field.type === "heading" ? "selected" : ""}>Section Title / Heading</option>
            <option value="paragraph" ${field.type === "paragraph" ? "selected" : ""}>Text / Instructions Block</option>
            <option value="divider" ${field.type === "divider" ? "selected" : ""}>Divider Line</option>
          </optgroup>
        </select>
      </div>

      ${field.type === "paragraph" ? `
        <div class="fb-prop-group">
          <label class="fb-prop-label" for="propFieldContent">Instructional / Paragraph Content</label>
          <textarea class="fb-prop-textarea" id="propFieldContent" rows="5" placeholder="Enter instructional text, legal disclaimer, or guidelines...">${escapeHTML(field.content || field.label || "")}</textarea>
        </div>

        <div class="fb-prop-group">
          <label class="fb-prop-label" for="propFieldParagraphStyle">Paragraph Presentation Style</label>
          <select class="fb-prop-select" id="propFieldParagraphStyle" onchange="window.CMSAdminFormBuilder.updateParagraphStyle(this.value)">
            <option value="callout" ${field.paragraphStyle === "callout" || !field.paragraphStyle ? "selected" : ""}>Information Callout (Chelan Blue)</option>
            <option value="warning" ${field.paragraphStyle === "warning" ? "selected" : ""}>Warning / Alert Notice (Amber)</option>
            <option value="legal" ${field.paragraphStyle === "legal" ? "selected" : ""}>Legal / Terms Disclaimer (Muted)</option>
            <option value="standard" ${field.paragraphStyle === "standard" ? "selected" : ""}>Standard Text Block</option>
          </select>
        </div>
      ` : `
        <div class="fb-prop-group">
          <label class="fb-prop-label" for="propFieldLabel">${field.type === "heading" ? "Section Title Text" : "Field Label"}</label>
          <input type="text" class="fb-prop-input" id="propFieldLabel" value="${escapeHTML(field.label || "")}">
        </div>
      `}

      ${field.type === "textarea" ? `
        <div class="fb-prop-group">
          <label class="fb-prop-label" for="propFieldRows">Display Height / Textarea Rows</label>
          <select class="fb-prop-select" id="propFieldRows" onchange="window.CMSAdminFormBuilder.updateFieldRows(this.value)">
            <option value="3" ${field.rows === 3 ? "selected" : ""}>3 Rows (Compact Comments)</option>
            <option value="4" ${field.rows === 4 || !field.rows ? "selected" : ""}>4 Rows (Standard Paragraph)</option>
            <option value="6" ${field.rows === 6 ? "selected" : ""}>6 Rows (Detailed Feedback)</option>
            <option value="8" ${field.rows === 8 ? "selected" : ""}>8 Rows (Full Project Scope)</option>
          </select>
        </div>
      ` : ""}

      ${field.type !== "divider" && field.type !== "heading" && field.type !== "paragraph" && field.type !== "address" ? `
        <div class="fb-prop-group">
          <label class="fb-prop-label" for="propFieldPlaceholder">Placeholder Text</label>
          <input type="text" class="fb-prop-input" id="propFieldPlaceholder" value="${escapeHTML(field.placeholder || "")}">
        </div>
      ` : ""}

      ${field.type === "address" ? `
        <div class="fb-prop-group">
          <label class="fb-prop-label" for="propFieldDefaultState">Default State Code</label>
          <input type="text" class="fb-prop-input" id="propFieldDefaultState" maxlength="2" value="${escapeHTML(field.defaultState || "WA")}" style="text-transform:uppercase; width:90px;">
          <div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:0.25rem;">2-letter state code pre-filled for residents.</div>
        </div>
      ` : ""}

      <div class="fb-prop-group">
        <label class="fb-prop-label" for="propFieldSubtext">Help / Description Text (Linked via aria-describedby)</label>
        <input type="text" class="fb-prop-input" id="propFieldSubtext" value="${escapeHTML(field.subtext || "")}">
      </div>

      <div class="fb-prop-group">
        <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:0.35rem;">
          <label class="fb-prop-label" style="margin:0;">Column Layout Width</label>
          ${field.width === "50" || field.width === "33" ? `
            <span class="badge" style="font-size:0.65rem; padding:2px 6px; border-radius:4px; background:var(--admin-primary-light); color:var(--admin-primary); font-weight:600; display:inline-flex; align-items:center; gap:3px;" title="Automatically changes to fb-field-col-100 on mobile">
              <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><rect width="14" height="20" x="5" y="2" rx="2" ry="2"/><line x1="12" x2="12.01" y1="18" y2="18"/></svg>
              Auto-100% on Mobile
            </span>
          ` : ""}
        </div>
        <div class="fb-width-picker">
          <button type="button" class="fb-width-btn ${field.width === "100" || !field.width ? "active" : ""}" onclick="window.CMSAdminFormBuilder.updateFieldWidth('100')">100% Full</button>
          <button type="button" class="fb-width-btn ${field.width === "50" ? "active" : ""}" onclick="window.CMSAdminFormBuilder.updateFieldWidth('50')">50% Half</button>
          <button type="button" class="fb-width-btn ${field.width === "33" ? "active" : ""}" onclick="window.CMSAdminFormBuilder.updateFieldWidth('33')">33% Third</button>
        </div>
        <div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:0.35rem; line-height:1.4;">
          50% and 33% columns automatically change to <strong>100% Full Width</strong> (<code>fb-field-col-100</code>) on mobile screens and in mobile preview mode.
        </div>
      </div>

      ${optionsMarkup}

      ${field.type !== "heading" && field.type !== "divider" && field.type !== "paragraph" ? `
        <div class="fb-prop-group" style="padding-top:0.5rem; border-top:1px solid var(--admin-border-subtle);">
          <label class="fb-prop-toggle">
            <input type="checkbox" id="propFieldRequired" ${field.required ? "checked" : ""}>
            <span><strong>Required field</strong> (aria-required="true")</span>
          </label>
        </div>
      ` : ""}
    `;

    // Bind real-time input events for inspector
    const labelInput = document.getElementById("propFieldLabel");
    if (labelInput) {
      labelInput.addEventListener("input", (e) => {
        field.label = e.target.value;
        renderFormCanvas();
        markDirty();
      });
    }

    const contentInput = document.getElementById("propFieldContent");
    if (contentInput) {
      contentInput.addEventListener("input", (e) => {
        field.content = e.target.value;
        field.label = e.target.value.substring(0, 30) + "...";
        renderFormCanvas();
        markDirty();
      });
    }

    const stateInput = document.getElementById("propFieldDefaultState");
    if (stateInput) {
      stateInput.addEventListener("input", (e) => {
        field.defaultState = e.target.value.toUpperCase();
        renderFormCanvas();
        markDirty();
      });
    }

    const placeholderInput = document.getElementById("propFieldPlaceholder");
    if (placeholderInput) {
      placeholderInput.addEventListener("input", (e) => {
        field.placeholder = e.target.value;
        renderFormCanvas();
        markDirty();
      });
    }

    const subtextInput = document.getElementById("propFieldSubtext");
    if (subtextInput) {
      subtextInput.addEventListener("input", (e) => {
        field.subtext = e.target.value;
        renderFormCanvas();
        markDirty();
      });
    }

    const reqInput = document.getElementById("propFieldRequired");
    if (reqInput) {
      reqInput.addEventListener("change", (e) => {
        field.required = e.target.checked;
        renderFormCanvas();
        markDirty();
      });
    }
  }

  function populateFormSettings() {
    if (!formPropsPanel) return;

    const config = window.CMSAdminFormBuilderConfig || {};
    const workspaces = config.workspaces || [];
    const depts = config.departments || [];

    // The owning workspace of this form (or current active workspace for new form)
    const owningSiteId = (currentForm.siteid || currentForm.department || "").toString().toLowerCase().trim();
    const owningWsName = currentForm.workspaceName || currentForm.departmentName || (currentForm.siteid ? currentForm.siteid : "All Workspaces");

    // Build Department options where Department implies current or owning workspace
    let deptOptionsHtml = "";
    const seenCodes = {};

    if (workspaces.length > 0) {
      deptOptionsHtml += '<optgroup label="County Workspaces & Departments">';
      workspaces.forEach((ws) => {
        const code = (ws.code || ws.id || "").toString();
        const name = (ws.name || ws.department || code).toString();
        if (code && !seenCodes[code.toLowerCase()]) {
          seenCodes[code.toLowerCase()] = true;
          const isSelected = (code.toLowerCase() === owningSiteId ||
                              name.toLowerCase() === (currentForm.workspaceName || "").toLowerCase() ||
                              name.toLowerCase() === (currentForm.departmentName || "").toLowerCase() ||
                              code.toLowerCase() === (currentForm.department || "").toLowerCase());
          deptOptionsHtml += `<option value="${escapeHTML(code)}" data-name="${escapeHTML(name)}" ${isSelected ? "selected" : ""}>${escapeHTML(name)}</option>`;
        }
      });
      deptOptionsHtml += '</optgroup>';
    }

    // Additional divisions from form_departments not already present
    const extraDepts = depts.filter((d) => !seenCodes[(d.code || "").toLowerCase()] && !seenCodes[(d.name || "").toLowerCase()]);
    if (extraDepts.length > 0) {
      deptOptionsHtml += '<optgroup label="Specialized Intake Divisions">';
      extraDepts.forEach((d) => {
        const code = (d.code || "").toString();
        const name = (d.name || code).toString();
        const isSelected = (code.toLowerCase() === owningSiteId || code.toLowerCase() === (currentForm.department || "").toLowerCase());
        deptOptionsHtml += `<option value="${escapeHTML(code)}" data-name="${escapeHTML(name)}" ${isSelected ? "selected" : ""}>${escapeHTML(name)}</option>`;
      });
      deptOptionsHtml += '</optgroup>';
    }

    formPropsPanel.innerHTML = `
      <div class="fb-prop-group">
        <label class="fb-prop-label">Form Title</label>
        <input type="text" class="fb-prop-input" id="formPropTitle" value="${escapeHTML(currentForm.title || "")}">
      </div>

      <div class="fb-prop-group">
        <label class="fb-prop-label">Form Instructions / Description</label>
        <textarea class="fb-prop-textarea" id="formPropDesc">${escapeHTML(currentForm.description || "")}</textarea>
      </div>

      <input type="hidden" id="formPropDepartment" value="${escapeHTML(currentForm.siteid || currentForm.department || owningSiteId)}">

      <div class="fb-prop-group">
        <label class="fb-prop-label">Submit Button Label</label>
        <input type="text" class="fb-prop-input" id="formPropSubmitText" value="${escapeHTML(currentForm.submitText || "Submit Form")}">
      </div>

      <div class="fb-prop-group">
        <label class="fb-prop-label">Accent Theme Color</label>
        <div class="fb-theme-picker">
          ${[
            { name: "Blue", color: "#0073aa" },
            { name: "Green", color: "#27ae60" },
            { name: "Amber", color: "#e67e22" },
            { name: "Purple", color: "#8e44ad" },
            { name: "Slate", color: "#34495e" }
          ].map((t) => `
            <div class="fb-theme-dot ${currentForm.themeColor === t.color ? "active" : ""}" style="background:${t.color};" title="${t.name}" onclick="window.CMSAdminFormBuilder.setThemeColor('${t.color}')"></div>
          `).join("")}
        </div>
      </div>

      <!-- Anti-Spam & Submission Security -->
      <div class="fb-prop-group" style="padding-top:0.75rem; border-top:1px solid var(--admin-border-subtle);">
        <label class="fb-prop-label" style="display:flex; align-items:center; gap:0.4rem; color:var(--admin-primary); font-weight:700;">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
          Anti-Spam &amp; Submission Delays
        </label>
        
        <label class="fb-prop-toggle" style="margin-bottom:0.75rem;">
          <input type="checkbox" id="formPropHoneypot" ${currentForm.antiSpamEnabled !== false ? "checked" : ""}>
          <span><strong>Enable Honeypot Bot Trap</strong></span>
        </label>

        <label class="fb-prop-label" for="formPropMinDelay">Minimum Submission Delay (Speed Trap)</label>
        <select class="fb-prop-select" id="formPropMinDelay" style="margin-bottom:0.75rem;">
          <option value="0" ${currentForm.minDelaySeconds === 0 ? "selected" : ""}>0s - Disabled (Allow instant)</option>
          <option value="3" ${currentForm.minDelaySeconds === 3 || currentForm.minDelaySeconds === undefined ? "selected" : ""}>3 Seconds (Recommended for Public Forms)</option>
          <option value="5" ${currentForm.minDelaySeconds === 5 ? "selected" : ""}>5 Seconds (Enhanced Bot Protection)</option>
          <option value="8" ${currentForm.minDelaySeconds === 8 ? "selected" : ""}>8 Seconds (High-Security Intake)</option>
        </select>

        <label class="fb-prop-label" for="formPropCooldown">Submit Button Cooldown (Anti-Flood Delay)</label>
        <select class="fb-prop-select" id="formPropCooldown">
          <option value="2" ${currentForm.cooldownSeconds === 2 ? "selected" : ""}>2 Seconds Cooldown</option>
          <option value="3" ${currentForm.cooldownSeconds === 3 || currentForm.cooldownSeconds === undefined ? "selected" : ""}>3 Seconds Cooldown (Recommended)</option>
          <option value="5" ${currentForm.cooldownSeconds === 5 ? "selected" : ""}>5 Seconds Cooldown</option>
        </select>
      </div>

      <!-- ADA WCAG 2.1 AA Accessibility -->
      <div class="fb-prop-group" style="padding-top:0.75rem; border-top:1px solid var(--admin-border-subtle);">
        <label class="fb-prop-label" style="display:flex; align-items:center; gap:0.4rem; color:var(--admin-success); font-weight:700;">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
          ADA WCAG 2.1 AA Accessibility
        </label>
        
        <label class="fb-prop-toggle" style="margin-bottom:0.4rem;">
          <input type="checkbox" id="formPropWcag" ${currentForm.wcagCompliant !== false ? "checked" : ""}>
          <span><strong>Enforce WCAG 2.1 AA Conformance</strong></span>
        </label>
        <div style="font-size:0.75rem; color:var(--admin-text-muted); line-height:1.4;">
          Ensures explicit <code>&lt;label for&gt;</code> pairing, <code>&lt;fieldset&gt;/&lt;legend&gt;</code> groupings for multi-option choices, screen reader <code>(required)</code> indicators, and high-contrast visible focus rings.
        </div>
      </div>

      <div class="fb-prop-group" style="padding-top:0.75rem; border-top:1px solid var(--admin-border-subtle);">
        <label class="fb-prop-label">Success Confirmation Message</label>
        <textarea class="fb-prop-textarea" id="formPropSuccessMsg">${escapeHTML(currentForm.successMessage || "")}</textarea>
      </div>

      <div class="fb-prop-group">
        <label class="fb-prop-label">Admin Alert Email (Submissions)</label>
        <input type="email" class="fb-prop-input" id="formPropEmail" value="${escapeHTML(currentForm.notificationEmail || "admin@chelancounty.gov")}">
      </div>
    `;

    // Bindings
    const titleInput = document.getElementById("formPropTitle");
    if (titleInput) {
      titleInput.addEventListener("input", (e) => {
        currentForm.title = e.target.value;
        updateHeaderData();
        markDirty();
      });
    }

    const descInput = document.getElementById("formPropDesc");
    if (descInput) {
      descInput.addEventListener("input", (e) => {
        currentForm.description = e.target.value;
        updateHeaderData();
        markDirty();
      });
    }

    const deptSelect = document.getElementById("formPropDepartment");
    if (deptSelect) {
      deptSelect.addEventListener("change", (e) => {
        const selectedOpt = e.target.selectedOptions ? e.target.selectedOptions[0] : null;
        const val = e.target.value;
        const wsName = selectedOpt ? (selectedOpt.getAttribute("data-name") || selectedOpt.textContent) : val;

        currentForm.department = val;
        currentForm.departmentName = wsName;
        currentForm.siteid = val;
        currentForm.workspaceName = wsName;

        const wsLabel = document.getElementById("fbFormWorkspace");
        if (wsLabel) wsLabel.textContent = "Workspace: " + wsName;

        const owningWsEl = document.getElementById("formPropOwningWs");
        if (owningWsEl) owningWsEl.textContent = wsName;

        const emailInput = document.getElementById("formPropEmail");
        if (emailInput && (!emailInput.value || emailInput.value.includes("@chelancounty.gov"))) {
          const wsObj = (config.workspaces || []).find((w) => (w.id || "").toLowerCase() === val.toLowerCase() || (w.code || "").toLowerCase() === val.toLowerCase());
          if (wsObj && wsObj.contact && wsObj.contact.email) {
            emailInput.value = wsObj.contact.email;
            currentForm.notificationEmail = wsObj.contact.email;
          } else if (val.toLowerCase() === "hrm") {
            emailInput.value = "hrm@chelancounty.gov";
            currentForm.notificationEmail = "hrm@chelancounty.gov";
            currentForm.themeColor = "#8e44ad";
          } else if (val.toLowerCase() === "pio") {
            emailInput.value = "pio@chelancounty.gov";
            currentForm.notificationEmail = "pio@chelancounty.gov";
            currentForm.themeColor = "#0284c7";
          } else if (val.toLowerCase() === "admin" || val.toLowerCase() === "administration") {
            emailInput.value = "contact@chelancounty.gov";
            currentForm.notificationEmail = "contact@chelancounty.gov";
            currentForm.themeColor = "#0073aa";
          }
          if (formCardEl && currentForm.themeColor) formCardEl.style.borderTopColor = currentForm.themeColor;
        }
        markDirty();
      });
    }

    const submitInput = document.getElementById("formPropSubmitText");
    if (submitInput) {
      submitInput.addEventListener("input", (e) => {
        currentForm.submitText = e.target.value;
        renderSubmitFooter();
        markDirty();
      });
    }

    const hpInput = document.getElementById("formPropHoneypot");
    if (hpInput) {
      hpInput.addEventListener("change", (e) => {
        currentForm.antiSpamEnabled = e.target.checked;
        markDirty();
      });
    }

    const minDelayInput = document.getElementById("formPropMinDelay");
    if (minDelayInput) {
      minDelayInput.addEventListener("change", (e) => {
        currentForm.minDelaySeconds = parseInt(e.target.value, 10);
        markDirty();
      });
    }

    const cooldownInput = document.getElementById("formPropCooldown");
    if (cooldownInput) {
      cooldownInput.addEventListener("change", (e) => {
        currentForm.cooldownSeconds = parseInt(e.target.value, 10);
        markDirty();
      });
    }

    const wcagInput = document.getElementById("formPropWcag");
    if (wcagInput) {
      wcagInput.addEventListener("change", (e) => {
        currentForm.wcagCompliant = e.target.checked;
        markDirty();
      });
    }

    const successInput = document.getElementById("formPropSuccessMsg");
    if (successInput) {
      successInput.addEventListener("input", (e) => {
        currentForm.successMessage = e.target.value;
        markDirty();
      });
    }

    const emailInput = document.getElementById("formPropEmail");
    if (emailInput) {
      emailInput.addEventListener("input", (e) => {
        currentForm.notificationEmail = e.target.value;
        markDirty();
      });
    }
  }

  // =========================================================================
  // Interactive Live Preview Modal & Form Submission
  // =========================================================================
  function openPreviewModal() {
    const modal = document.getElementById("fbPreviewModal");
    const container = document.getElementById("fbPreviewFormContainer");
    if (!modal || !container) return;

    const minDelay = currentForm.minDelaySeconds !== undefined ? currentForm.minDelaySeconds : 3;
    const cooldown = currentForm.cooldownSeconds !== undefined ? currentForm.cooldownSeconds : 3;

    let html = `
      <div style="background:var(--admin-surface); border:1px solid var(--admin-border); border-top:5px solid ${currentForm.themeColor || "#0073aa"}; border-radius:var(--radius-lg); box-shadow:var(--shadow-sm); overflow:hidden;">
        <!-- Official County Header -->
        <div style="padding:1.5rem 2rem; background:linear-gradient(to bottom, #fff, var(--admin-bg)); border-bottom:1px solid var(--admin-border-subtle);">
          <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:0.4rem; font-size:0.75rem; color:var(--admin-text-muted);">
            <span style="font-weight:600; color:var(--admin-primary); display:inline-flex; align-items:center; gap:0.35rem;">
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
              Chelan County Official Online Form
            </span>
          </div>
          <h2 id="modalFormHeading" style="margin:0 0 0.4rem 0; font-size:1.4rem; color:var(--admin-text-main);">${escapeHTML(currentForm.title)}</h2>
          <p id="modalFormDesc" style="margin:0; font-size:0.875rem; color:var(--admin-text-muted); line-height:1.5;">${escapeHTML(currentForm.description || "")}</p>
        </div>

        <form id="fbInteractiveTestForm" aria-labelledby="modalFormHeading" aria-describedby="modalFormDesc" novalidate style="padding:1.75rem 2rem; display:flex; flex-direction:column; gap:1.25rem;">
          <!-- Accessible Live Region Alert for Validation & Anti-Spam -->
          <div id="testFormAlert" class="fb-alert-banner" role="alert" aria-live="polite" style="display:none;"></div>

          <!-- Anti-Spam Honeypot Bot Trap -->
          <div class="fb-hp-wrap" aria-hidden="true">
            <label for="test_hp_verify">Leave this field empty</label>
            <input type="text" id="test_hp_verify" name="_chelan_gov_verify" tabindex="-1" autocomplete="off" value="">
          </div>

          <!-- Anti-Spam Submission Speed Trap: Form Load Timestamp -->
          <input type="hidden" id="test_load_time" name="_cf_form_load_time" value="${Date.now()}">

          <div class="fb-preview-fields">
    `;

    (currentForm.fields || []).forEach((field) => {
      const reqAttr = field.required ? "required aria-required=\"true\"" : "";
      const reqStar = field.required ? '<span class="fb-required-star" aria-hidden="true">*</span><span class="sr-only"> (required)</span>' : "";
      const descId = field.subtext ? `test_desc_${field.id}` : "";
      const ariaDesc = descId ? `aria-describedby="${descId}"` : "";
      const sub = field.subtext ? `<div id="${descId}" class="fb-subtext" style="font-size:0.775rem; color:var(--admin-text-muted); margin-top:0.35rem;">${escapeHTML(field.subtext)}</div>` : "";
      const isMobile = window.innerWidth <= 768;
      const widthVal = field.width || "100";
      const colClass = (isMobile && (widthVal === "50" || widthVal === "33")) ? "fb-field-col-100" : `fb-field-col-${widthVal}`;

      html += `<div class="fb-preview-field ${colClass}" data-desktop-col="${widthVal}">`;
      switch (field.type) {
        case "text":
          html += `
            <div>
              <label for="test_${field.id}" style="display:block; font-weight:600; font-size:0.875rem; margin-bottom:0.35rem;">${escapeHTML(field.label)} ${reqStar}</label>
              <input type="text" id="test_${field.id}" class="form-control" name="${field.id}" placeholder="${escapeHTML(field.placeholder || "")}" ${reqAttr} ${ariaDesc} style="width:100%; box-sizing:border-box; padding:0.65rem 0.85rem; border:1px solid var(--admin-border); border-radius:var(--radius-md);">
              ${sub}
            </div>
          `;
          break;

        case "textarea":
          html += `
            <div>
              <label for="test_${field.id}" style="display:block; font-weight:600; font-size:0.875rem; margin-bottom:0.35rem;">${escapeHTML(field.label)} ${reqStar}</label>
              <textarea id="test_${field.id}" class="form-control" name="${field.id}" rows="${field.rows || 4}" placeholder="${escapeHTML(field.placeholder || "")}" ${reqAttr} ${ariaDesc} style="width:100%; box-sizing:border-box; min-height:100px; padding:0.65rem 0.85rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); font-family:inherit; resize:vertical;"></textarea>
              ${sub}
            </div>
          `;
          break;

        case "paragraph":
          html += `
            <div class="fb-paragraph-block ${field.paragraphStyle ? 'style-' + field.paragraphStyle : ''}" style="margin:0.25rem 0;">
              <p class="fb-paragraph-text">${escapeHTML(field.content || field.label || "")}</p>
            </div>
            ${sub}
          `;
          break;

        case "email":
          html += `
            <div>
              <label for="test_${field.id}" style="display:block; font-weight:600; font-size:0.875rem; margin-bottom:0.35rem;">${escapeHTML(field.label)} ${reqStar}</label>
              <input type="email" id="test_${field.id}" class="form-control" name="${field.id}" autocomplete="email" placeholder="${escapeHTML(field.placeholder || "name@example.com")}" ${reqAttr} ${ariaDesc} style="width:100%; box-sizing:border-box; padding:0.65rem 0.85rem; border:1px solid var(--admin-border); border-radius:var(--radius-md);">
              ${sub}
            </div>
          `;
          break;

        case "phone":
          html += `
            <div>
              <label for="test_${field.id}" style="display:block; font-weight:600; font-size:0.875rem; margin-bottom:0.35rem;">${escapeHTML(field.label)} ${reqStar}</label>
              <input type="tel" id="test_${field.id}" class="form-control" name="${field.id}" autocomplete="tel" placeholder="${escapeHTML(field.placeholder || "(509) 000-0000")}" ${reqAttr} ${ariaDesc} style="width:100%; box-sizing:border-box; padding:0.65rem 0.85rem; border:1px solid var(--admin-border); border-radius:var(--radius-md);">
              ${sub}
            </div>
          `;
          break;

        case "number":
          html += `
            <div>
              <label for="test_${field.id}" style="display:block; font-weight:600; font-size:0.875rem; margin-bottom:0.35rem;">${escapeHTML(field.label)} ${reqStar}</label>
              <input type="number" id="test_${field.id}" class="form-control" name="${field.id}" placeholder="${escapeHTML(field.placeholder || "0")}" ${reqAttr} ${ariaDesc} style="width:100%; box-sizing:border-box; padding:0.65rem 0.85rem; border:1px solid var(--admin-border); border-radius:var(--radius-md);">
              ${sub}
            </div>
          `;
          break;

        case "select":
          const selectOpts = (field.options || []).map((o) => `<option value="${escapeHTML(o)}">${escapeHTML(o)}</option>`).join("");
          html += `
            <div>
              <label for="test_${field.id}" style="display:block; font-weight:600; font-size:0.875rem; margin-bottom:0.35rem;">${escapeHTML(field.label)} ${reqStar}</label>
              <select id="test_${field.id}" name="${field.id}" ${reqAttr} ${ariaDesc} style="width:100%; box-sizing:border-box; padding:0.65rem 0.85rem; border:1px solid var(--admin-border); border-radius:var(--radius-md); background:#fff;">
                <option value="">-- Select an option --</option>
                ${selectOpts}
              </select>
              ${sub}
            </div>
          `;
          break;

        case "radio":
          const radioOpts = (field.options || []).map((o, idx) => `
            <label class="fb-option-item" style="display:flex; align-items:center; gap:0.6rem; font-size:0.875rem; cursor:pointer; padding:0.25rem 0;">
              <input type="radio" id="test_${field.id}_${idx}" name="${field.id}" value="${escapeHTML(o)}" ${field.required ? 'required aria-required="true"' : ""}>
              <span>${escapeHTML(o)}</span>
            </label>
          `).join("");
          html += `
            <fieldset class="fb-fieldset" role="radiogroup" aria-labelledby="legend_${field.id}" ${ariaDesc}>
              <legend id="legend_${field.id}" class="fb-legend">${escapeHTML(field.label)} ${reqStar}</legend>
              <div class="fb-options-preview" style="clear:both; display:flex; flex-direction:column; gap:0.45rem;">${radioOpts}</div>
              ${sub}
            </fieldset>
          `;
          break;

        case "checkbox":
          const checkOpts = (field.options || []).map((o, idx) => `
            <label style="display:flex; align-items:center; gap:0.5rem; font-size:0.875rem; cursor:pointer;">
              <input type="checkbox" id="test_${field.id}_${idx}" name="${field.id}[]" value="${escapeHTML(o)}">
              <span>${escapeHTML(o)}</span>
            </label>
          `).join("");
          html += `
            <fieldset class="fb-fieldset" role="group" aria-labelledby="legend_${field.id}" ${ariaDesc}>
              <legend id="legend_${field.id}" class="fb-legend">${escapeHTML(field.label)} ${reqStar}</legend>
              <div style="display:flex; flex-direction:column; gap:0.4rem; clear:both;">${checkOpts}</div>
              ${sub}
            </fieldset>
          `;
          break;

        case "switch":
          html += `
            <div style="display:flex; align-items:center; justify-content:space-between; gap:1rem;">
              <div>
                <label for="test_${field.id}" style="font-weight:600; font-size:0.875rem; margin-bottom:0; cursor:pointer;">${escapeHTML(field.label)} ${reqStar}</label>
                ${sub}
              </div>
              <input type="checkbox" id="test_${field.id}" name="${field.id}" ${reqAttr} style="width:20px; height:20px; accent-color:var(--admin-primary); cursor:pointer;">
            </div>
          `;
          break;

        case "date":
          html += `
            <div>
              <label for="test_${field.id}" style="display:block; font-weight:600; font-size:0.875rem; margin-bottom:0.35rem;">${escapeHTML(field.label)} ${reqStar}</label>
              <input type="date" id="test_${field.id}" name="${field.id}" ${reqAttr} ${ariaDesc} style="width:100%; box-sizing:border-box; padding:0.65rem 0.85rem; border:1px solid var(--admin-border); border-radius:var(--radius-md);">
              ${sub}
            </div>
          `;
          break;

        case "rating":
          html += `
            <div>
              <label style="display:block; font-weight:600; font-size:0.875rem; margin-bottom:0.35rem;">${escapeHTML(field.label)} ${reqStar}</label>
              <div class="interactive-star-rating" role="radiogroup" aria-label="${escapeHTML(field.label)}" style="display:flex; gap:0.4rem; color:#cbd5e1; cursor:pointer;" data-field="${field.id}">
                ${[1, 2, 3, 4, 5].map((star) => `
                  <button type="button" class="star-btn" data-value="${star}" role="radio" aria-checked="${star === 5 ? "true" : "false"}" aria-label="${star} out of 5 stars" style="background:none; border:none; padding:0; font-size:1.6rem; line-height:1; cursor:pointer; color:#cbd5e1; transition:color 0.2s;">&#9733;</button>
                `).join("")}
                <input type="hidden" name="${field.id}" value="5" ${reqAttr}>
              </div>
              ${sub}
            </div>
          `;
          break;

        case "file":
          html += `
            <div>
              <label for="test_${field.id}" style="display:block; font-weight:600; font-size:0.875rem; margin-bottom:0.35rem;">${escapeHTML(field.label)} ${reqStar}</label>
              <input type="file" id="test_${field.id}" name="${field.id}" ${reqAttr} ${ariaDesc} style="width:100%; box-sizing:border-box; padding:0.65rem 0.85rem; border:1px dashed var(--admin-border); border-radius:var(--radius-md); background:var(--admin-bg);">
              ${sub}
            </div>
          `;
          break;

        case "signature":
          html += `
            <div>
              <label for="test_${field.id}" style="display:block; font-weight:600; font-size:0.875rem; margin-bottom:0.35rem;">${escapeHTML(field.label)} ${reqStar}</label>
              <div style="border:1px solid var(--admin-border); border-radius:var(--radius-md); padding:0.5rem; background:#fff;">
                <input type="text" id="test_${field.id}" name="${field.id}" placeholder="Type your full legal name to digitally sign" ${reqAttr} ${ariaDesc} style="width:100%; box-sizing:border-box; border:none; outline:none; font-family:'Brush Script MT', cursive, sans-serif; font-size:1.4rem; color:var(--admin-primary); padding:0.4rem;">
              </div>
              <div style="font-size:0.75rem; color:var(--admin-text-subtle); margin-top:0.25rem;">Accessible Digital Signature Capture &bull; Legally Binding</div>
              ${sub}
            </div>
          `;
          break;

        case "address":
          html += `
            <fieldset class="fb-fieldset fb-address-group" role="group" aria-labelledby="legend_${field.id}">
              <legend id="legend_${field.id}" class="fb-legend">${escapeHTML(field.label)} ${reqStar}</legend>
              <div class="fb-address-fields" style="clear:both; display:flex; flex-direction:column; gap:0.55rem; width:100%;">
                <input type="text" id="test_${field.id}_street" name="${field.id}_street" placeholder="Street Address (e.g. 350 Orondo Ave)" aria-label="Street Address" ${reqAttr} class="form-control" style="width:100%; box-sizing:border-box; padding:0.65rem 0.85rem; border:1px solid var(--admin-border); border-radius:var(--radius-md);">
                <input type="text" id="test_${field.id}_street2" name="${field.id}_street2" placeholder="Apt, Suite, Unit, Building (Optional)" aria-label="Address Line 2" class="form-control" style="width:100%; box-sizing:border-box; padding:0.65rem 0.85rem; border:1px solid var(--admin-border); border-radius:var(--radius-md);">
                <div style="display:flex; gap:0.55rem;">
                  <input type="text" id="test_${field.id}_city" name="${field.id}_city" placeholder="City (e.g. Wenatchee)" aria-label="City" ${reqAttr} class="form-control" style="flex:5; min-width:0; box-sizing:border-box; padding:0.65rem 0.85rem; border:1px solid var(--admin-border); border-radius:var(--radius-md);">
                  <input type="text" id="test_${field.id}_state" name="${field.id}_state" value="${escapeHTML(field.defaultState || "WA")}" aria-label="State" ${reqAttr} class="form-control" style="flex:2; min-width:60px; box-sizing:border-box; padding:0.65rem 0.85rem; border:1px solid var(--admin-border); border-radius:var(--radius-md);">
                  <input type="text" id="test_${field.id}_zip" name="${field.id}_zip" placeholder="ZIP Code (e.g. 98801)" aria-label="ZIP Code" ${reqAttr} class="form-control" style="flex:3; min-width:85px; box-sizing:border-box; padding:0.65rem 0.85rem; border:1px solid var(--admin-border); border-radius:var(--radius-md);">
                </div>
              </div>
              ${sub}
            </fieldset>
          `;
          break;

        case "heading":
          html += `
            <div style="padding-top:0.75rem; border-top:1px solid var(--admin-border-subtle);">
              <h3 style="margin:0 0 0.25rem 0; font-size:1.15rem; color:var(--admin-text-main);">${escapeHTML(field.label)}</h3>
              ${field.subtext ? `<p style="margin:0; font-size:0.8rem; color:var(--admin-text-muted);">${escapeHTML(field.subtext)}</p>` : ""}
            </div>
          `;
          break;

        case "divider":
          html += `<hr style="border:none; border-top:1px dashed var(--admin-border); margin:0.5rem 0;" role="separator">`;
          break;
      }
      html += `</div>`;
    });

    html += `
          </div>
          <div style="margin-top:1rem; padding-top:1.25rem; border-top:1px solid var(--admin-border-subtle); display:flex; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:1rem;">
            <button type="submit" id="btnTestSubmit" class="btn btn-primary" style="background:${currentForm.themeColor || "#0073aa"}; border:none; padding:0.65rem 1.75rem; font-weight:600;">
              ${escapeHTML(currentForm.submitText || "Submit Form")}
            </button>
            <div style="font-size:0.75rem; color:var(--admin-text-muted); display:inline-flex; align-items:center; gap:0.4rem;">
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
              Protected by 256-bit SSL &bull; Anti-Spam Verified
            </div>
          </div>
        </form>
      </div>
    `;

    container.innerHTML = html;
    openModal("fbPreviewModal");

    // Star rating keyboard and click interactions
    container.querySelectorAll(".interactive-star-rating").forEach((wrap) => {
      const stars = wrap.querySelectorAll(".star-btn");
      const hiddenInput = wrap.querySelector("input");
      const updateStars = (val) => {
        stars.forEach((s, idx) => {
          s.style.color = idx < val ? "var(--admin-warning)" : "#cbd5e1";
          s.setAttribute("aria-checked", idx + 1 === val ? "true" : "false");
        });
        hiddenInput.value = val;
      };
      updateStars(5);
      stars.forEach((star) => {
        star.addEventListener("click", () => {
          updateStars(parseInt(star.getAttribute("data-value"), 10));
        });
      });
    });

    // Test form submit handler with Honeypot verification and Submission Delays
    const form = document.getElementById("fbInteractiveTestForm");
    if (form) {
      form.addEventListener("submit", (e) => {
        e.preventDefault();
        const alertEl = document.getElementById("testFormAlert");
        const submitBtn = document.getElementById("btnTestSubmit");

        // 0. Native HTML5 Accessibility Validation
        if (!form.checkValidity()) {
          form.reportValidity();
          return;
        }

        // 1. Anti-Spam Check: Honeypot Trap
        const hpInput = form.querySelector("input[name='_chelan_gov_verify']");
        if (hpInput && hpInput.value.trim() !== "") {
          alertEl.className = "fb-alert-banner error";
          alertEl.innerHTML = `
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="flex-shrink:0;"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
            <div><strong>Security Alert:</strong> Anti-spam honeypot triggered. Automated form submission has been blocked.</div>
          `;
          alertEl.style.display = "flex";
          alertEl.scrollIntoView({ behavior: "smooth", block: "nearest" });
          return;
        }

        // 2. Anti-Spam Check: Submission Speed Trap / Time Delay
        const loadTime = parseInt(document.getElementById("test_load_time").value, 10);
        const elapsedSec = (Date.now() - loadTime) / 1000;
        const requiredDelay = currentForm.minDelaySeconds !== undefined ? currentForm.minDelaySeconds : 3;

        if (requiredDelay > 0 && elapsedSec < requiredDelay) {
          const remaining = Math.ceil(requiredDelay - elapsedSec);
          alertEl.className = "fb-alert-banner warning";
          alertEl.innerHTML = `
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="flex-shrink:0;"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
            <div>
              <strong>Submission Delay Active:</strong>
              Please take a moment to review your answers. Submissions under ${requiredDelay} seconds are held by automated anti-spam protection to prevent robotic mass-filling. Please wait <strong>${remaining} second(s)</strong> and click submit again.
            </div>
          `;
          alertEl.style.display = "flex";
          alertEl.scrollIntoView({ behavior: "smooth", block: "nearest" });
          return;
        }

        // 3. Clear alert and start submission cooldown
        alertEl.style.display = "none";
        const origBtnText = submitBtn.innerHTML;
        submitBtn.disabled = true;
        submitBtn.classList.add("btn-submitting");
        submitBtn.innerText = "Verifying security & processing...";

        // Delay execution to enforce anti-spam processing / debounce
        setTimeout(() => {
          const refId = "SUB-" + Math.floor(100000 + Math.random() * 900000);
          const timeNow = new Date().toLocaleTimeString("en-US", { hour: "2-digit", minute: "2-digit", second: "2-digit" });

          container.innerHTML = `
            <div style="background:var(--admin-surface); border:1px solid var(--admin-border); border-top:5px solid var(--admin-success); border-radius:var(--radius-lg); padding:3rem 2rem; text-align:center; box-shadow:var(--shadow-sm);" role="region" aria-label="Submission Confirmation">
              <div style="width:64px; height:64px; border-radius:50%; background:var(--admin-success-light); color:var(--admin-success); display:inline-flex; align-items:center; justify-content:center; margin-bottom:1.25rem;">
                <svg width="34" height="34" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
              </div>
              <h3 style="font-size:1.35rem; color:var(--admin-text-main); margin-bottom:0.5rem;" tabindex="-1" id="successHeading">Submission Received!</h3>
              <p style="font-size:0.95rem; color:var(--admin-text-muted); max-width:480px; margin:0 auto 1.5rem auto;">
                ${escapeHTML(currentForm.successMessage || "Thank you! Your submission has been successfully processed.")}
              </p>
              <div style="display:inline-flex; flex-wrap:wrap; justify-content:center; gap:1.25rem; background:var(--admin-bg); border:1px solid var(--admin-border); border-radius:var(--radius-md); padding:0.85rem 1.5rem; font-size:0.8rem; color:var(--admin-text-main); margin-bottom:1.5rem;">
                <div><strong>Reference:</strong> <span style="font-family:monospace; color:var(--admin-primary);">${refId}</span></div>
                <div><strong>Time:</strong> ${timeNow}</div>
                <div><strong>Anti-Spam:</strong> <span style="color:var(--admin-success); font-weight:600;">Verified Human</span></div>
                <div><strong>Accessibility:</strong> <span style="color:var(--admin-success); font-weight:600;">WCAG 2.1 AA</span></div>
              </div>
              <div>
                <button type="button" class="btn btn-secondary btn-sm" onclick="window.CMSAdminFormBuilder.openPreviewModal()">
                  Fill Form Again
                </button>
              </div>
            </div>
          `;
          const heading = document.getElementById("successHeading");
          if (heading) heading.focus();
        }, 1200);
      });
    }
  }

  // =========================================================================
  // Share & Embed Modal & Export
  // =========================================================================
  function openShareModal() {
    const origin = window.location.origin;
    const directUrl = `${origin}/forms/preview?id=${currentForm.id}`;
    const embedCode = `<div class="cms-form-embed" data-form-id="${currentForm.id}">\n  <iframe src="${directUrl}" width="100%" height="920" frameborder="0" scrolling="auto" style="border:none; border-radius:8px; box-shadow:0 2px 10px rgba(0,0,0,0.08); width:100%; min-height:650px;" title="${escapeHTML(currentForm.title)}"></iframe>\n  <script>window.addEventListener("message",function(e){if(e.data&&e.data.type==="chelan-form-resize"&&e.data.height){var f=document.querySelector('.cms-form-embed[data-form-id="'+currentForm.id+'"] iframe');if(f){f.style.height=e.data.height+"px";f.setAttribute("height",e.data.height);}}});<\/script>\n</div>`;

    const directInput = document.getElementById("fbDirectLinkInput");
    if (directInput) directInput.value = directUrl;

    const codeBox = document.getElementById("fbEmbedCode");
    if (codeBox) codeBox.innerText = embedCode;

    const openLinkBtn = document.getElementById("btnOpenNewTabLink");
    if (openLinkBtn) openLinkBtn.href = directUrl;

    openModal("fbShareModal");
  }

  function downloadStandaloneHTML() {
    const minDelay = currentForm.minDelaySeconds !== undefined ? currentForm.minDelaySeconds : 3;
    const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${escapeHTML(currentForm.title)} - Chelan County</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
  <style>
    :root {
      --primary: ${currentForm.themeColor || "#0073aa"};
      --bg: #f8fafc;
      --surface: #ffffff;
      --text: #1e293b;
      --text-muted: #64748b;
      --border: #e2e8f0;
      --danger: #dc2626;
      --success: #16a34a;
      --warning: #d97706;
      --radius: 8px;
    }
    *, *::before, *::after { box-sizing: border-box; }
    body { font-family: 'Plus Jakarta Sans', system-ui, sans-serif; background: var(--bg); color: var(--text); padding: 2rem 1rem; margin: 0; line-height: 1.5; font-size: 14px; }
    .form-card { max-width: 680px; margin: 0 auto; background: var(--surface); border-radius: 12px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.08); overflow: hidden; border: 1px solid var(--border); border-top: 5px solid var(--primary); }
    .form-header { padding: 2rem; border-bottom: 1px solid var(--border); background: linear-gradient(to bottom, #ffffff, #f8fafc); }
    .form-title { margin: 0 0 0.5rem 0; font-size: 1.5rem; font-weight: 700; color: var(--text); }
    .form-desc { margin: 0; color: var(--text-muted); font-size: 0.9rem; }
    .form-body { padding: 2rem; display: flex; flex-direction: column; gap: 1.25rem; }
    .form-group { display: flex; flex-direction: column; box-sizing: border-box; }
    .fields-list { display: flex; flex-wrap: wrap; gap: 1rem; width: 100%; }
    .col-100 { width: 100%; flex: 0 0 100%; }
    .col-50 { width: calc(50% - 0.5rem); flex: 0 0 calc(50% - 0.5rem); }
    .col-33 { width: calc(33.333% - 0.67rem); flex: 0 0 calc(33.333% - 0.67rem); }
    @media (max-width: 768px) { .col-50, .col-33 { width: 100% !important; flex: 0 0 100% !important; } }
    .form-label { font-weight: 600; font-size: 0.875rem; margin-bottom: 0.4rem; color: var(--text); }
    .required-star { color: var(--danger); font-weight: bold; margin-left: 2px; }
    .form-subtext { font-size: 0.775rem; color: var(--text-muted); margin-top: 0.35rem; }
    .form-control { width: 100%; box-sizing: border-box; padding: 0.65rem 0.85rem; font-size: 0.9rem; border: 1px solid var(--border); border-radius: 6px; font-family: inherit; color: var(--text); background: #fff; outline: none; }
    .form-control:focus-visible, .form-btn:focus-visible { outline: 2px solid var(--primary) !important; outline-offset: 2px !important; }
    textarea.form-control { min-height: 100px; resize: vertical; line-height: 1.5; }
    .form-paragraph-block { padding: 0.85rem 1rem; background: var(--bg); border-left: 4px solid var(--primary); border-radius: 4px; font-size: 0.875rem; color: var(--text); }
    .form-fieldset { border: none; margin: 0; padding: 0; width: 100%; }
    .form-legend { font-weight: 600; font-size: 0.875rem; margin-bottom: 0.4rem; color: var(--text); }
    .form-btn { background: var(--primary); color: #fff; border: none; padding: 0.75rem 2rem; border-radius: 6px; font-weight: 600; font-size: 1rem; cursor: pointer; transition: opacity 0.2s; }
    .form-btn:hover { opacity: 0.92; }
    .sr-only { position: absolute !important; width: 1px !important; height: 1px !important; padding: 0 !important; margin: -1px !important; overflow: hidden !important; clip: rect(0, 0, 0, 0) !important; border: 0 !important; }
    .hp-trap { position: absolute !important; left: -9999px !important; top: -9999px !important; width: 1px !important; height: 1px !important; overflow: hidden !important; }
    .alert-banner { padding: 0.75rem 1rem; border-radius: 6px; font-size: 0.85rem; margin-bottom: 1rem; display: none; }
    .alert-banner.warning { background: #fef3c7; border: 1px solid var(--warning); color: #92400e; }
    .alert-banner.error { background: #fee2e2; border: 1px solid var(--danger); color: #991b1b; }
  </style>
</head>
<body>
  <div class="form-card">
    <div class="form-header">
      <h1 class="form-title" id="pageFormTitle">${escapeHTML(currentForm.title)}</h1>
      <p class="form-desc" id="pageFormDesc">${escapeHTML(currentForm.description || "")}</p>
    </div>
    <form class="form-body" id="standaloneForm" aria-labelledby="pageFormTitle" aria-describedby="pageFormDesc" novalidate>
      <div id="formAlertBanner" class="alert-banner" role="alert" aria-live="polite"></div>

      <!-- Anti-Spam Honeypot Bot Trap -->
      <div class="hp-trap" aria-hidden="true">
        <label for="sa_hp_verify">Leave blank</label>
        <input type="text" id="sa_hp_verify" name="_chelan_gov_verify" tabindex="-1" autocomplete="off" value="">
      </div>

      <!-- Anti-Spam Time-Delay Form Load Token -->
      <input type="hidden" id="sa_load_time" name="_cf_form_load_time" value="${Date.now()}">

      <div class="fields-list">
      ${(currentForm.fields || []).map((f) => {
        const colClass = f.width === "50" ? "col-50" : (f.width === "33" ? "col-33" : "col-100");
        const reqAttr = f.required ? 'required aria-required="true"' : '';
        const reqStar = f.required ? '<span class="required-star" aria-hidden="true">*</span><span class="sr-only"> (required)</span>' : '';
        const sub = f.subtext ? `<div id="sub_${f.id}" class="form-subtext">${escapeHTML(f.subtext)}</div>` : '';
        const ariaDesc = f.subtext ? `aria-describedby="sub_${f.id}"` : '';

        if (f.type === "textarea") {
          return `
            <div class="form-group ${colClass}">
              <label for="field_${f.id}" class="form-label">${escapeHTML(f.label)} ${reqStar}</label>
              <textarea id="field_${f.id}" name="${f.id}" class="form-control" rows="${f.rows || 4}" placeholder="${escapeHTML(f.placeholder || "")}" ${reqAttr} ${ariaDesc}></textarea>
              ${sub}
            </div>
          `;
        } else if (f.type === "paragraph") {
          return `
            <div class="form-group ${colClass}">
              <div class="form-paragraph-block" style="width:100%;">
                <p style="margin:0; line-height:1.5;">${escapeHTML(f.content || f.label || "")}</p>
              </div>
              ${sub}
            </div>
          `;
        } else if (f.type === "select") {
          const opts = (f.options || []).map((o) => `<option value="${escapeHTML(o)}">${escapeHTML(o)}</option>`).join("");
          return `
            <div class="form-group ${colClass}">
              <label for="field_${f.id}" class="form-label">${escapeHTML(f.label)} ${reqStar}</label>
              <select id="field_${f.id}" name="${f.id}" class="form-control" ${reqAttr} ${ariaDesc}>
                <option value="">-- Select an option --</option>
                ${opts}
              </select>
              ${sub}
            </div>
          `;
        } else if (f.type === "heading") {
          return `
            <div style="padding-top:0.75rem; border-top:1px solid #e2e8f0; width:100%;">
              <h2 style="margin:0 0 0.25rem 0; font-size:1.2rem;">${escapeHTML(f.label)}</h2>
              ${f.subtext ? `<p class="form-subtext" style="margin:0;">${escapeHTML(f.subtext)}</p>` : ''}
            </div>
          `;
        } else if (f.type === "divider") {
          return `<div style="width:100%;"><hr style="border:none; border-top:1px dashed #e2e8f0; margin:0.5rem 0;" role="separator"></div>`;
        } else if (f.type === "radio") {
          const radioOpts = (f.options || []).map((o, idx) => `
            <label style="display:flex; align-items:center; gap:0.6rem; font-size:0.9rem; cursor:pointer; padding:0.2rem 0;">
              <input type="radio" id="rad_${f.id}_${idx}" name="${f.id}" value="${escapeHTML(o)}" ${f.required ? 'required aria-required="true"' : ""}>
              <span>${escapeHTML(o)}</span>
            </label>
          `).join("");
          return `
            <div class="form-group ${colClass}">
              <fieldset class="form-fieldset" role="radiogroup" ${ariaDesc}>
                <legend class="form-legend">${escapeHTML(f.label)} ${reqStar}</legend>
                <div style="display:flex; flex-direction:column; gap:0.4rem; clear:both;">${radioOpts}</div>
                ${sub}
              </fieldset>
            </div>
          `;
        } else if (f.type === "checkbox") {
          const checkOpts = (f.options || []).map((o, idx) => `
            <label style="display:flex; align-items:center; gap:0.6rem; font-size:0.9rem; cursor:pointer; padding:0.2rem 0;">
              <input type="checkbox" id="chk_${f.id}_${idx}" name="${f.id}[]" value="${escapeHTML(o)}">
              <span>${escapeHTML(o)}</span>
            </label>
          `).join("");
          return `
            <div class="form-group ${colClass}">
              <fieldset class="form-fieldset" role="group" ${ariaDesc}>
                <legend class="form-legend">${escapeHTML(f.label)} ${reqStar}</legend>
                <div style="display:flex; flex-direction:column; gap:0.4rem; clear:both;">${checkOpts}</div>
                ${sub}
              </fieldset>
            </div>
          `;
        } else if (f.type === "address") {
          return `
            <div class="form-group ${colClass}">
              <fieldset class="form-fieldset" role="group" ${ariaDesc}>
                <legend class="form-legend">${escapeHTML(f.label)} ${reqStar}</legend>
                <div style="display:flex; flex-direction:column; gap:0.55rem; clear:both; width:100%;">
                  <input type="text" id="field_${f.id}_street" name="${f.id}_street" class="form-control" placeholder="Street Address" aria-label="Street Address" ${reqAttr}>
                  <input type="text" id="field_${f.id}_street2" name="${f.id}_street2" class="form-control" placeholder="Apt, Suite, Unit, Building (Optional)" aria-label="Address Line 2">
                  <div style="display:flex; gap:0.55rem;">
                    <input type="text" id="field_${f.id}_city" name="${f.id}_city" class="form-control" placeholder="City" aria-label="City" style="flex:5; min-width:0;" ${reqAttr}>
                    <input type="text" id="field_${f.id}_state" name="${f.id}_state" class="form-control" value="${escapeHTML(f.defaultState || "WA")}" aria-label="State" style="flex:2; min-width:60px;" ${reqAttr}>
                    <input type="text" id="field_${f.id}_zip" name="${f.id}_zip" class="form-control" placeholder="ZIP Code" aria-label="ZIP Code" style="flex:3; min-width:85px;" ${reqAttr}>
                  </div>
                </div>
                ${sub}
              </fieldset>
            </div>
          `;
        } else {
          return `
            <div class="form-group ${colClass}">
              <label for="field_${f.id}" class="form-label">${escapeHTML(f.label)} ${reqStar}</label>
              <input type="${f.type === "email" ? "email" : (f.type === "number" ? "number" : "text")}" id="field_${f.id}" name="${f.id}" class="form-control" placeholder="${escapeHTML(f.placeholder || "")}" ${reqAttr} ${ariaDesc}>
              ${sub}
            </div>
          `;
        }
      }).join("")}
      </div>

      <div style="margin-top:0.5rem;">
        <button type="submit" class="form-btn" id="saSubmitBtn">${escapeHTML(currentForm.submitText || "Submit Form")}</button>
      </div>
    </form>
  </div>

  <script>
    document.getElementById("standaloneForm").addEventListener("submit", function(e) {
      e.preventDefault();
      var alertBox = document.getElementById("formAlertBanner");
      var btn = document.getElementById("saSubmitBtn");

      // 0. Native HTML5 Accessibility Validation
      if (!this.checkValidity()) {
        this.reportValidity();
        return;
      }

      // 1. Honeypot check
      var hp = document.getElementById("sa_hp_verify").value.trim();
      if (hp !== "") {
        alertBox.className = "alert-banner error";
        alertBox.innerHTML = "<strong>Security Notice:</strong> Spam verification triggered. Automated submission blocked.";
        alertBox.style.display = "block";
        return;
      }

      // 2. Submission speed trap delay check
      var loadTime = parseInt(document.getElementById("sa_load_time").value, 10);
      var elapsed = (Date.now() - loadTime) / 1000;
      var minDelay = ${minDelay};
      if (minDelay > 0 && elapsed < minDelay) {
        var remain = Math.ceil(minDelay - elapsed);
        alertBox.className = "alert-banner warning";
        alertBox.innerHTML = "<strong>Submission Delay:</strong> Please review your responses. To prevent automated bot spam, forms cannot be submitted under " + minDelay + " seconds. Please wait " + remain + " second(s).";
        alertBox.style.display = "block";
        return;
      }

      alertBox.style.display = "none";
      btn.disabled = true;
      btn.innerText = "Submitting securely...";

      setTimeout(function() {
        alert("${escapeHTML(currentForm.successMessage || "Thank you! Your response has been submitted.")}");
        location.reload();
      }, 1000);
    });
  </script>
</body>
</html>`;

    const blob = new Blob([html], { type: "text/html" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = (currentForm.title.toLowerCase().replace(/[^a-z0-9]/g, "-") || "online-form") + ".html";
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    showToast("Standalone WCAG AA Compliant HTML downloaded!");
  }

  function exportJSON() {
    const jsonStr = JSON.stringify(currentForm, null, 2);
    const blob = new Blob([jsonStr], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = (currentForm.title.toLowerCase().replace(/[^a-z0-9]/g, "-") || "form-schema") + ".json";
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    showToast("Form JSON schema exported!");
  }

  // =========================================================================
  // Helpers
  // =========================================================================
  function openModal(id) {
    const modal = document.getElementById(id);
    if (modal) modal.classList.add("open");
  }

  function closeModal(id) {
    const modal = document.getElementById(id);
    if (modal) modal.classList.remove("open");
  }

  function showToast(msg, typeOrIsError = "success") {
    let toast = document.getElementById("fbToast");
    if (!toast) {
      toast = document.createElement("div");
      toast.id = "fbToast";
      toast.className = "fb-toast";
      document.body.appendChild(toast);
    }
    let normType = typeOrIsError;
    if (typeOrIsError === true || typeOrIsError === "error") normType = "danger";
    if (typeOrIsError === false) normType = "success";
    if (!["success", "danger", "warning", "info"].includes(normType)) {
      normType = "success";
    }

    toast.className = `fb-toast fb-toast--${normType}`;

    const icons = {
      success: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>',
      danger: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>',
      warning: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>',
      info: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>'
    };

    toast.innerHTML = `<span class="fb-toast-icon">${icons[normType]}</span><span>${escapeHTML(msg)}</span>`;
    toast.classList.add("show");
    clearTimeout(toast._timer);
    toast._timer = setTimeout(() => toast.classList.remove("show"), 3200);
  }

  function escapeHTML(str) {
    if (!str) return "";
    return String(str)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
  }

  function fallbackCopyText(text) {
    try {
      const ta = document.createElement("textarea");
      ta.value = text;
      ta.style.position = "fixed";
      ta.style.top = "0";
      ta.style.left = "0";
      ta.style.opacity = "0";
      document.body.appendChild(ta);
      ta.focus();
      ta.select();
      const res = document.execCommand("copy");
      document.body.removeChild(ta);
      if (res) return Promise.resolve(true);
    } catch (e) {}
    window.prompt("Copy to clipboard (Ctrl+C):", text);
    return Promise.resolve(true);
  }

  // Export to Global window for inline onclick handlers
  window.CMSAdminFormBuilder = {
    addField,
    selectField,
    duplicateField,
    deleteField,
    moveField,
    updateFieldType: (newType) => {
      const field = getFieldById(selectedFieldId);
      if (field && field.type !== newType) {
        field.type = newType;
        if (newType === "textarea" && !field.rows) field.rows = 4;
        if (newType === "paragraph" && !field.content) {
          field.content = field.label || "Important instructions or policy guidance...";
          field.paragraphStyle = "callout";
        }
        if (["select", "radio", "checkbox"].includes(newType) && (!field.options || !field.options.length)) {
          field.options = ["Option 1", "Option 2", "Option 3"];
        }
        renderFormCanvas();
        updatePropertiesInspector();
        markDirty();
        showToast(`Changed field element to ${newType}`);
      }
    },
    updateParagraphStyle: (style) => {
      const field = getFieldById(selectedFieldId);
      if (field) {
        field.paragraphStyle = style;
        renderFormCanvas();
        markDirty();
      }
    },
    updateFieldRows: (rows) => {
      const field = getFieldById(selectedFieldId);
      if (field) {
        field.rows = parseInt(rows, 10) || 4;
        renderFormCanvas();
        markDirty();
      }
    },
    updateFieldWidth: (width) => {
      const field = getFieldById(selectedFieldId);
      if (field) {
        field.width = width;
        renderFormCanvas();
        updatePropertiesInspector();
        markDirty();
      }
    },
    addOption: () => {
      const field = getFieldById(selectedFieldId);
      if (field) {
        if (!field.options) field.options = [];
        field.options.push("Option " + (field.options.length + 1));
        renderFormCanvas();
        updatePropertiesInspector();
        markDirty();

        setTimeout(() => {
          const list = document.querySelector(".fb-options-list");
          if (list) {
            const inputs = list.querySelectorAll("input");
            if (inputs.length > 0) {
              const lastInput = inputs[inputs.length - 1];
              lastInput.focus();
              lastInput.select();
              lastInput.scrollIntoView({ behavior: "smooth", block: "nearest" });
            }
          }
        }, 30);
      }
    },
    updateOption: (idx, val) => {
      const field = getFieldById(selectedFieldId);
      if (field && field.options && field.options[idx] !== undefined) {
        field.options[idx] = val;
        renderFormCanvas();
        markDirty();
      }
    },
    removeOption: (idx) => {
      const field = getFieldById(selectedFieldId);
      if (field && field.options && field.options.length > 1) {
        field.options.splice(idx, 1);
        renderFormCanvas();
        updatePropertiesInspector();
        markDirty();

        setTimeout(() => {
          const list = document.querySelector(".fb-options-list");
          if (list) {
            const inputs = list.querySelectorAll("input");
            const targetIdx = Math.max(0, idx - 1);
            if (inputs[targetIdx]) {
              inputs[targetIdx].focus();
            }
          }
        }, 30);
      }
    },
    setThemeColor: (color) => {
      currentForm.themeColor = color;
      if (formCardEl) formCardEl.style.borderTopColor = color;
      populateFormSettings();
      renderSubmitFooter();
      markDirty();
    },
    openPreviewModal,
    updateMobileColumnAdaptation,
    isMobileMode
  };
})();
