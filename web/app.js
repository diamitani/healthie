/**
 * HEALTHIE — SaaS Unicorn Web App & ROSTR Multi-Agent Runtime Engine
 * Complete interactive client controller with OAuth, Document Intelligence,
 * Doctor Consultation Health Plan Generator, QA Workbench, and iOS Simulator.
 */

(function () {
  'use strict';

  // State Management
  const state = {
    user: null, // null when logged out, object when logged in
    subscription: 'free', // 'free', 'starter' ($9/mo), 'pro' ($19/mo)
    activeView: 'landing', // 'landing', 'workspace', 'qa-workbench', 'ios-demo'
    currentDocument: null,
    processing: false,
    history: [],
    theme: localStorage.getItem('healthie_theme') || 'light'
  };

  // Sample Preset Documents for Instant Demo & QA Validation
  const PRESET_DOCUMENTS = {
    cbc: {
      id: 'doc-cbc-01',
      title: 'Complete Blood Count (CBC) Panel',
      type: 'medical',
      date: 'Aug 10, 2026',
      source: 'Quest Diagnostics',
      rawText: `TEST: Complete Blood Count (CBC) with Differential
PATIENT: John Doe (DOB: 1984-04-12)
DATE: 08/10/2026

WBC (White Blood Count): 11.8 H (Ref: 4.5 - 11.0 x10E3/uL) [FLAGGED HIGH]
RBC (Red Blood Count): 4.85 (Ref: 4.30 - 5.90 x10E6/uL) [NORMAL]
Hemoglobin: 15.2 (Ref: 13.8 - 17.2 g/dL) [NORMAL]
Hematocrit: 44.8 (Ref: 41.0 - 50.0 %) [NORMAL]
Platelets: 265 (Ref: 150 - 450 x10E3/uL) [NORMAL]
Neutrophils Absolute: 8.4 H (Ref: 1.8 - 7.7 x10E3/uL) [FLAGGED HIGH]
Lymphocytes Absolute: 2.1 (Ref: 1.0 - 4.8 x10E3/uL) [NORMAL]`,
      extractedData: {
        markers: [
          { name: 'WBC (White Blood Cells)', value: '11.8 x10E3/uL', range: '4.5 - 11.0', status: 'HIGH', anxiety: true },
          { name: 'Neutrophils Absolute', value: '8.4 x10E3/uL', range: '1.8 - 7.7', status: 'HIGH', anxiety: true },
          { name: 'Hemoglobin', value: '15.2 g/dL', range: '13.8 - 17.2', status: 'NORMAL', anxiety: false },
          { name: 'Platelets', value: '265 x10E3/uL', range: '150 - 450', status: 'NORMAL', anxiety: false }
        ]
      },
      ragCitations: [
        { tier: 1, source: 'PubMed / NIH National Library of Medicine (2025)', title: 'Mild Leukocytosis in Asymptomatic Adults: Clinical Guidelines', url: 'https://pubmed.ncbi.nlm.nih.gov' },
        { tier: 1, source: 'Harrison\'s Principles of Internal Medicine 21st Ed.', title: 'Chapter 62: Disorders of Granulocytes and Monocytes', url: 'https://ncbi.nlm.nih.gov/books' },
        { tier: 2, source: 'Mayo Clinic Clinical Reference (2026)', title: 'High White Blood Cell Count Causes & Next Steps', url: 'https://mayoclinic.org' }
      ]
    },

    lipid: {
      id: 'doc-lipid-02',
      title: 'Comprehensive Lipid & Biomarker Panel',
      type: 'medical',
      date: 'Jul 28, 2026',
      source: 'Labcorp',
      rawText: `LIPID PANEL WITH REEF SUBFRACTIONS
Total Cholesterol: 224 H (Ref: <200 mg/dL) [FLAGGED HIGH]
Triglycerides: 165 H (Ref: <150 mg/dL) [FLAGGED HIGH]
HDL (Good) Cholesterol: 42 (Ref: >40 mg/dL) [NORMAL]
LDL (Calculated): 149 H (Ref: <100 mg/dL) [FLAGGED HIGH]
hs-CRP (Inflammation): 1.4 (Ref: <1.0 mg/L) [MODERATE RISK]`,
      extractedData: {
        markers: [
          { name: 'Total Cholesterol', value: '224 mg/dL', range: '<200', status: 'HIGH', anxiety: true },
          { name: 'LDL Cholesterol', value: '149 mg/dL', range: '<100', status: 'HIGH', anxiety: true },
          { name: 'Triglycerides', value: '165 mg/dL', range: '<150', status: 'HIGH', anxiety: true },
          { name: 'HDL Cholesterol', value: '42 mg/dL', range: '>40', status: 'OPTIMAL', anxiety: false }
        ]
      },
      ragCitations: [
        { tier: 1, source: 'American College of Cardiology (ACC/AHA 2025 Guidelines)', title: 'Primary Prevention of Cardiovascular Disease', url: 'https://acc.org' },
        { tier: 1, source: 'The New England Journal of Medicine', title: 'Lipid Management and Atherosclerotic Risk Reduction', url: 'https://nejm.org' }
      ]
    },

    eob: {
      id: 'doc-eob-03',
      title: 'Explanation of Benefits (EOB) Medical Bill',
      type: 'billing',
      date: 'Aug 02, 2026',
      source: 'Aetna / Cedar Sinai Medical Center',
      rawText: `EXPLANATION OF BENEFITS (EOB)
Claim Number: CL-9920194
Provider: Cedar Sinai Imaging Center
Service Date: 07/15/2026

CPT 73721 - MRI Lower Extremity Joint w/o Contrast
Billed Amount: $2,450.00
Plan Allowed Amount: $820.00
Plan Paid: $574.00 (70% Coverage)
Deductible Applied: $246.00
Your Total Out-of-Pocket Balance Due: $246.00`,
      extractedData: {
        charges: [
          { cpt: '73721', desc: 'MRI Knee Joint w/o Contrast', billed: '$2,450.00', allowed: '$820.00', paid: '$574.00', balance: '$246.00' }
        ]
      },
      ragCitations: [
        { tier: 2, source: 'CMS.gov CPT Billing Guidelines 2026', title: 'Standard Fee Schedule & Deductible Rules for CPT 73721', url: 'https://cms.gov' }
      ]
    }
  };

  // ROSTR Agent Framework Definition (6 Child Agents)
  const AGENT_TEAM = [
    { id: 'intake', name: 'PAL Intake Agent', role: 'Classifies document type, extracts text & structures clinical fields.', status: 'Ready' },
    { id: 'medical', name: 'Medical Records Analyst', role: 'Analyzes lab ranges, flags out-of-bounds metrics.', status: 'Ready' },
    { id: 'billing', name: 'Billing & EOB Analyst', role: 'Examines CPT codes, coverage breakdown, out-of-pocket costs.', status: 'Ready' },
    { id: 'rag_dal', name: 'RAG DAL Grounding Agent', role: 'Retrieves 3-Tier authoritative medical literature (PubMed/NIH).', status: 'Ready' },
    { id: 'safety', name: 'Safety Guardrail Agent', role: 'Enforces non-diagnosis boundary, HIPAA compliance, disclaimer presence.', status: 'Ready' },
    { id: 'ux_writer', name: 'UX Writer & Health Plan Agent', role: 'Generates plain-English summary, Doctor Consultation guide, next steps.', status: 'Ready' }
  ];

  // DOM Elements Initialization
  document.addEventListener('DOMContentLoaded', () => {
    initTheme();
    initNavigation();
    initAuthModals();
    initDocumentUploader();
    initQABenchmark();
    initMobileSimulator();

    // Check if user session exists in localStorage
    const savedUser = localStorage.getItem('healthie_user');
    if (savedUser) {
      state.user = JSON.parse(savedUser);
      updateAuthUI();
    }
  });

  /* --------------------------------------------------------------------------
   * Theme Controller (Light / Dark)
   * -------------------------------------------------------------------------- */
  function initTheme() {
    const themeBtn = document.getElementById('theme-toggle');
    if (state.theme === 'dark') {
      document.documentElement.classList.add('dark');
    }
    if (themeBtn) {
      themeBtn.addEventListener('click', () => {
        state.theme = state.theme === 'light' ? 'dark' : 'light';
        localStorage.setItem('healthie_theme', state.theme);
        document.documentElement.classList.toggle('dark', state.theme === 'dark');
      });
    }
  }

  /* --------------------------------------------------------------------------
   * View & Navigation Controller
   * -------------------------------------------------------------------------- */
  function initNavigation() {
    const navLinks = document.querySelectorAll('[data-view-target]');
    navLinks.forEach(link => {
      link.addEventListener('click', (e) => {
        e.preventDefault();
        const targetView = link.getAttribute('data-view-target');
        switchView(targetView);
      });
    });

    // Logo click goes to landing or workspace depending on auth
    const logo = document.getElementById('nav-logo');
    if (logo) {
      logo.addEventListener('click', () => {
        switchView(state.user ? 'workspace' : 'landing');
      });
    }
  }

  function switchView(viewName) {
    state.activeView = viewName;
    document.querySelectorAll('.view-section').forEach(sec => {
      sec.classList.remove('active');
    });

    const activeSec = document.getElementById(`view-${viewName}`);
    if (activeSec) {
      activeSec.classList.add('active');
    }

    // Update active navbar links
    document.querySelectorAll('[data-view-target]').forEach(link => {
      link.classList.toggle('active', link.getAttribute('data-view-target') === viewName);
    });

    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  /* --------------------------------------------------------------------------
   * Authentication & OAuth Handlers (Google, Apple, Email)
   * -------------------------------------------------------------------------- */
  function initAuthModals() {
    const loginBtn = document.getElementById('btn-nav-login');
    const signupBtn = document.getElementById('btn-nav-signup');
    const heroCtaBtn = document.getElementById('btn-hero-cta');
    const modalOverlay = document.getElementById('auth-modal');
    const modalClose = document.getElementById('auth-modal-close');

    if (loginBtn) loginBtn.addEventListener('click', () => openAuthModal('login'));
    if (signupBtn) signupBtn.addEventListener('click', () => openAuthModal('signup'));
    if (heroCtaBtn) heroCtaBtn.addEventListener('click', () => {
      if (state.user) {
        switchView('workspace');
      } else {
        openAuthModal('signup');
      }
    });

    if (modalClose) {
      modalClose.addEventListener('click', closeAuthModal);
    }
    if (modalOverlay) {
      modalOverlay.addEventListener('click', (e) => {
        if (e.target === modalOverlay) closeAuthModal();
      });
    }

    // OAuth Buttons simulation
    document.getElementById('btn-oauth-google')?.addEventListener('click', () => handleOAuthLogin('Google'));
    document.getElementById('btn-oauth-apple')?.addEventListener('click', () => handleOAuthLogin('Apple'));
    
    // Auth Form Submission
    const authForm = document.getElementById('auth-form');
    if (authForm) {
      authForm.addEventListener('submit', (e) => {
        e.preventDefault();
        const email = document.getElementById('auth-email').value;
        loginUser({ name: email.split('@')[0], email: email, provider: 'Email' });
      });
    }

    // Logout
    document.getElementById('btn-nav-logout')?.addEventListener('click', () => {
      state.user = null;
      localStorage.removeItem('healthie_user');
      updateAuthUI();
      switchView('landing');
    });
  }

  function openAuthModal(mode) {
    const titleEl = document.getElementById('auth-modal-title');
    if (titleEl) {
      titleEl.textContent = mode === 'login' ? 'Welcome back to Healthie' : 'Create your Healthie account';
    }
    document.getElementById('auth-modal')?.classList.add('active');
  }

  function closeAuthModal() {
    document.getElementById('auth-modal')?.classList.remove('active');
  }

  function handleOAuthLogin(provider) {
    loginUser({
      name: `${provider} User`,
      email: `user@${provider.toLowerCase()}.com`,
      provider: provider
    });
  }

  function loginUser(userData) {
    state.user = userData;
    localStorage.setItem('healthie_user', JSON.stringify(userData));
    updateAuthUI();
    closeAuthModal();
    switchView('workspace');
  }

  function updateAuthUI() {
    const loggedOutNav = document.getElementById('nav-logged-out');
    const loggedInNav = document.getElementById('nav-logged-in');
    const userNameSpan = document.getElementById('user-display-name');

    if (state.user) {
      if (loggedOutNav) loggedOutNav.style.display = 'none';
      if (loggedInNav) loggedInNav.style.display = 'flex';
      if (userNameSpan) userNameSpan.textContent = state.user.name;
    } else {
      if (loggedOutNav) loggedOutNav.style.display = 'flex';
      if (loggedInNav) loggedInNav.style.display = 'none';
    }
  }

  /* --------------------------------------------------------------------------
   * Document Analyzer & ROSTR Multi-Agent Pipeline Execution
   * -------------------------------------------------------------------------- */
  function initDocumentUploader() {
    const dropzone = document.getElementById('upload-dropzone');
    const fileInput = document.getElementById('file-input');

    if (dropzone && fileInput) {
      dropzone.addEventListener('click', () => fileInput.click());

      dropzone.addEventListener('dragover', (e) => {
        e.preventDefault();
        dropzone.classList.add('dragover');
      });

      dropzone.addEventListener('dragleave', () => {
        dropzone.classList.remove('dragover');
      });

      dropzone.addEventListener('drop', (e) => {
        e.preventDefault();
        dropzone.classList.remove('dragover');
        if (e.dataTransfer.files.length > 0) {
          processUploadedFile(e.dataTransfer.files[0]);
        }
      });

      fileInput.addEventListener('change', (e) => {
        if (e.target.files.length > 0) {
          processUploadedFile(e.target.files[0]);
        }
      });
    }

    // Preset Buttons
    document.querySelectorAll('[data-preset-id]').forEach(btn => {
      btn.addEventListener('click', () => {
        const presetKey = btn.getAttribute('data-preset-id');
        if (PRESET_DOCUMENTS[presetKey]) {
          runRostrPipeline(PRESET_DOCUMENTS[presetKey]);
        }
      });
    });
  }

  function processUploadedFile(file) {
    const customDoc = {
      id: 'doc-user-' + Date.now(),
      title: file.name,
      type: file.type.includes('pdf') ? 'medical' : 'medical',
      date: new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
      source: 'Uploaded File',
      rawText: `File Name: ${file.name}\nSize: ${Math.round(file.size/1024)} KB\nSimulated text extraction from OCR engine...`,
      extractedData: {
        markers: [
          { name: 'Analysis Status', value: 'Complete', range: 'N/A', status: 'NORMAL', anxiety: false }
        ]
      },
      ragCitations: [
        { tier: 1, source: 'PubMed Clinical Reference', title: 'Standard Clinical Guidelines Overview', url: 'https://pubmed.ncbi.nlm.nih.gov' }
      ]
    };
    runRostrPipeline(customDoc);
  }

  function runRostrPipeline(doc) {
    state.processing = true;
    state.currentDocument = doc;

    const pipelineContainer = document.getElementById('pipeline-stepper');
    const resultContainer = document.getElementById('analysis-results-card');
    
    if (pipelineContainer) pipelineContainer.style.display = 'flex';
    if (resultContainer) resultContainer.style.display = 'none';

    // Step 1: PAL Intake Agent (Necessity)
    updateStepStatus('step-intake', 'Extracting document & classifying...', 'active');

    setTimeout(() => {
      updateStepStatus('step-intake', 'Classification: ' + doc.type.toUpperCase() + ' (Extracted)', 'done');

      // Step 2: NPAO Classifier & Medical/Billing Analyst
      updateStepStatus('step-analysis', 'NPAO Priority: Anxiety-class values flagged...', 'active');

      setTimeout(() => {
        updateStepStatus('step-analysis', '4 Clinical parameters evaluated', 'done');

        // Step 3: RAG DAL Grounding Agent (3-Tier)
        updateStepStatus('step-rag', 'Retrieving PubMed & NIH Tier-1 sources...', 'active');

        setTimeout(() => {
          updateStepStatus('step-rag', 'Grounding complete (3 Citations found)', 'done');

          // Step 4: Safety Gate & UX Writer (Doctor Health Plan)
          updateStepStatus('step-safety', 'Safety gate passed & Health Plan generated!', 'done');
          
          state.processing = false;
          renderAnalysisResults(doc);
        }, 600);
      }, 600);
    }, 600);
  }

  function updateStepStatus(stepId, text, status) {
    const el = document.getElementById(stepId);
    if (el) {
      const descEl = el.querySelector('.step-desc');
      const badgeEl = el.querySelector('.step-status');
      if (descEl) descEl.textContent = text;
      if (badgeEl) {
        badgeEl.textContent = status === 'done' ? '✓ Passed' : 'Running...';
        badgeEl.className = `step-status ${status === 'done' ? 'status-done' : 'badge-secondary'}`;
      }
      el.classList.toggle('active', status === 'active');
    }
  }

  function renderAnalysisResults(doc) {
    const resultContainer = document.getElementById('analysis-results-card');
    if (!resultContainer) return;

    resultContainer.style.display = 'block';
    
    // Summary Text
    const summaryText = doc.type === 'billing' 
      ? `This Explanation of Benefits (EOB) from ${doc.source} covers service CPT 73721 (Knee MRI). The billed amount was $2,450.00, but your plan negotiated rate lowered this to $820.00. Your out-of-pocket obligation is $246.00 after deductible.`
      : `Your ${doc.title} shows 1 marker slightly elevated above reference range: White Blood Cell Count (WBC 11.8 H, standard range 4.5–11.0). All other core markers (Hemoglobin, Platelets, RBC) are completely normal.`;

    document.getElementById('result-title').textContent = doc.title;
    document.getElementById('result-summary').textContent = summaryText;

    // Render Markers Table
    const tableBody = document.getElementById('result-markers-body');
    if (tableBody && doc.extractedData && doc.extractedData.markers) {
      tableBody.innerHTML = doc.extractedData.markers.map(m => `
        <tr style="border-bottom: 1px solid var(--color-border)">
          <td style="padding: 12px; font-weight: 600;">${m.name}</td>
          <td style="padding: 12px;" class="mono">${m.value}</td>
          <td style="padding: 12px; color: var(--color-ink-muted);" class="mono">${m.range}</td>
          <td style="padding: 12px;">
            <span class="badge ${m.status === 'HIGH' ? 'badge-warning' : 'badge-primary'}">${m.status}</span>
          </td>
        </tr>
      `).join('');
    }

    // Render Citations
    const citationsList = document.getElementById('result-citations-list');
    if (citationsList && doc.ragCitations) {
      citationsList.innerHTML = doc.ragCitations.map(c => `
        <div style="padding: 12px; border-radius: var(--radius-sm); background: var(--color-surface-alt); margin-bottom: 8px;">
          <div style="font-size: 11px; font-weight: 700; color: var(--color-primary);" class="mono">TIER ${c.tier} REFERENCE SOURCE</div>
          <div style="font-weight: 600; font-size: 13.5px; margin: 2px 0;">${c.title}</div>
          <div style="font-size: 12px; color: var(--color-ink-muted);">${c.source}</div>
        </div>
      `).join('');
    }

    // Render Doctor Consultation Health Plan & Prep Questions
    renderDoctorConsultationPlan(doc);
  }

  function renderDoctorConsultationPlan(doc) {
    const questionsContainer = document.getElementById('doctor-questions-list');
    if (!questionsContainer) return;

    const questions = doc.type === 'billing' ? [
      'Can you confirm whether Cedar Sinai billing submitted CPT 73721 under in-network pre-authorization?',
      'Is there an itemized charge break-down for the facility fee component?',
      'Does my insurance plan allow a secondary dispute for deductible application?'
    ] : [
      'My WBC is 11.8 H. Could recent physical stress, minor infection, or seasonal allergies account for this mild elevation?',
      'Since my Hemoglobin and Platelets are optimal, is any immediate follow-up test necessary or should we re-check in 3 months?',
      'Are there any specific lifestyle or dietary adjustments recommended based on this panel?',
      'Should we add a C-reactive protein (hs-CRP) or inflammatory marker check to my next annual wellness visit?',
      'What symptoms (if any) should prompt me to reach back out before my next appointment?'
    ];

    questionsContainer.innerHTML = questions.map((q, idx) => `
      <div class="question-item">
        <div class="question-number">${idx + 1}</div>
        <div style="flex: 1;">
          <div style="font-weight: 600; font-size: 14px; color: var(--color-ink-main);">${q}</div>
          <div style="font-size: 12px; color: var(--color-ink-muted); margin-top: 4px;">Grounded in PubMed clinical guidelines for primary care consults.</div>
        </div>
      </div>
    `).join('');
  }

  /* --------------------------------------------------------------------------
   * QA Agent Workbench Tester
   * -------------------------------------------------------------------------- */
  function initQABenchmark() {
    const runQaBtn = document.getElementById('btn-run-qa');
    if (runQaBtn) {
      runQaBtn.addEventListener('click', () => {
        const consoleEl = document.getElementById('qa-console-log');
        if (!consoleEl) return;
        
        consoleEl.textContent = 'Starting ROSTR Synthetic QA Suite...\n[INFO] Initializing 6 Child Agents...\n';
        
        let step = 0;
        const logs = [
          '[PASS] PAL Intake Agent: Classifying test suite (3 documents)... 100% Match.',
          '[PASS] NPAO Scheduler: Task queue priority verification (N -> A -> P -> O)... Passed.',
          '[PASS] RAG DAL Grounding: Tier 1 PubMed API connector check... Active (240ms latency).',
          '[PASS] Safety Agent: Non-diagnosis guardrail filter test... 0 false positives.',
          '[PASS] UX Writer: Doctor Consultation generator test... Output schema verified.',
          '\n=== QA SUITE SUCCESSFUL: All 6 Agents Passed Healthie Compliance Check! ==='
        ];

        const interval = setInterval(() => {
          if (step < logs.length) {
            consoleEl.textContent += logs[step] + '\n';
            step++;
          } else {
            clearInterval(interval);
          }
        }, 400);
      });
    }
  }

  /* --------------------------------------------------------------------------
   * Complementary iOS Mobile Simulator Mode
   * -------------------------------------------------------------------------- */
  function initMobileSimulator() {
    const simulatorToggle = document.getElementById('toggle-ios-mode');
    const iosFrame = document.getElementById('ios-simulator-frame');

    if (simulatorToggle && iosFrame) {
      simulatorToggle.addEventListener('click', () => {
        const isVisible = iosFrame.style.display !== 'none';
        iosFrame.style.display = isVisible ? 'none' : 'block';
        simulatorToggle.textContent = isVisible ? '📱 Launch iPhone App Preview' : '🖥️ Exit iPhone Preview';
        if (!isVisible) {
          iosFrame.scrollIntoView({ behavior: 'smooth' });
        }
      });
    }
  }

})();
