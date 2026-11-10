;;; test-hud-modeline-defaults.el --- Settings lifecycle tests -*- lexical-binding: t; -*-
(require 'ert)
(require 'hud-modeline)

(defvar sprite-instance-id)
(defvar hud-modeline-test-setting 'original)

(ert-deftest hud-modeline-settings-lifecycle ()
  (let ((hud-modeline--saved-settings nil)
        (hud-modeline-settings '((hud-modeline-test-setting . nil)
                                 (unbound-hud-modeline-test-setting . new)))
        (hud-modeline-test-setting 'original))
    (unwind-protect
        (progn
          (makunbound 'unbound-hud-modeline-test-setting)
          (with-temp-buffer
            (setq-local hud-modeline-test-setting 'local)
            (hud-modeline--apply-settings)
            (should (eq hud-modeline-test-setting 'local))
            (should-not (default-value 'hud-modeline-test-setting))
            (should (eq (default-value 'unbound-hud-modeline-test-setting) 'new))
            (hud-modeline--restore-settings)
            (should (eq hud-modeline-test-setting 'local)))
          (should (eq hud-modeline-test-setting 'original))
          (should-not (default-boundp 'unbound-hud-modeline-test-setting)))
      (hud-modeline--restore-settings)
      (makunbound 'unbound-hud-modeline-test-setting))))

(ert-deftest hud-modeline-settings-title-and-anzu ()
  (let ((hud-modeline--saved-settings nil)
        (frame-title-format 'previous-title)
        (anzu-cons-mode-line-p t))
    (unwind-protect
        (progn
          (hud-modeline--apply-settings)
          (should (equal (default-value 'frame-title-format)
                         hud-modeline-frame-title-format))
          (should-not (default-value 'anzu-cons-mode-line-p))
          (with-temp-buffer
            (setq-local frame-title-format 'local-title)
            (hud-modeline--restore-settings)
            (should (eq frame-title-format 'local-title)))
          (should (eq frame-title-format 'previous-title))
          (should anzu-cons-mode-line-p))
      (hud-modeline--restore-settings))))

(ert-deftest hud-modeline-title-instance-provider ()
  (with-temp-buffer
    (rename-buffer "hud-title-test" t)
    (let ((sprite-instance-id "named-instance")
          (hud-modeline-instance-identity-function
           #'hud-modeline--sprite-instance-id))
      (should (equal (hud-modeline--frame-title) "named-instance:hud-title-test"))
      (setq sprite-instance-id nil)
      (should (equal (hud-modeline--frame-title) "emacs:hud-title-test"))
      (setq hud-modeline-instance-identity-function (lambda () "custom"))
      (should (equal (hud-modeline--frame-title) "custom:hud-title-test"))
      (setq hud-modeline-instance-identity-function nil)
      (should (equal (hud-modeline--frame-title) "emacs:hud-title-test")))))

(ert-deftest hud-modeline-repeated-enable-and-restore-format ()
  (let ((hud-modeline--saved-format nil)
        (hud-modeline--saved-settings nil)
        (mode-line-format 'original))
    (unwind-protect
        (progn
          (hud-modeline-mode 1)
          (hud-modeline-mode 1)
          (hud-modeline-mode -1)
          (should (eq (default-value 'mode-line-format) 'original)))
      (hud-modeline-mode -1))))

(ert-deftest hud-modeline-frame-name-preserved ()
  (let* ((frame (selected-frame))
         (prior (frame-parameter frame 'name))
         (hud-modeline--saved-settings nil))
    (unwind-protect
        (progn
          (modify-frame-parameters frame '((name . "hud-user-title")))
          (hud-modeline--apply-settings)
          (should (equal (frame-parameter frame 'name) "hud-user-title"))
          (hud-modeline--restore-settings)
          (should (equal (frame-parameter frame 'name) "hud-user-title")))
      (hud-modeline--restore-settings)
      (modify-frame-parameters frame `((name . ,prior))))))

(provide 'test-hud-modeline-defaults)
;;; test-hud-modeline-defaults.el ends here
