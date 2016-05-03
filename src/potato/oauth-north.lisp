(in-package :potato.oauth-north)

(declaim #.potato.common::*compile-decl*)

(defclass potato-north-server (north:server)
  ())

(defvar *server* (make-instance 'potato-north-server))

(defun make-request (request)
  (make-instance 'north:request
                 :http-method (hunchentoot:request-method* request)
                 :url (north::normalize-url
                       (format nil "~a~a" potato:*external-listen-address* (hunchentoot:request-uri* request)))
                 :parameters (append (hunchentoot:post-parameters* request)
                                     (hunchentoot:get-parameters* request)) 
                 :headers (hunchentoot:headers-in* request)))

(lofn:define-handler-fn (oauth-request-token "/oauth/request-token" nil ())
  (multiple-value-bind (token secret callback-confirmed)
      (north:oauth/request-token *server* (make-request hunchentoot:*request*))
    (setf (hunchentoot:content-type*) "text/plain")
    (north:alist->oauth-response `(("oauth_token" . ,token)
                                   ("oauth_token_secret" . ,secret)
                                   ("oauth_callback_confirmed" . ,(if callback-confirmed :true :false))))))

(lofn:define-handler-fn (oauth-authorise "/oauth/authorize" nil ())
  (lofn:with-checked-parameters ((oauth-token :name "oauth_token" :required t :allow-blank nil)
                                 (verifier :name "verifier")
                                 (error-link :name "error"))
    (let* ((session (or (north:session *server* oauth-token)
                        (error 'north:invalid-token :request (make-request hunchentoot:*request*))))
           (application (north:application *server* (north:key session))))
      (setf (hunchentoot:content-type*) "application/html")
      (lofn:show-template-stream "oauth-authorise.tmpl"
                                 `((:oauth-token . ,oauth-token)
                                   (:application . ,(north:name application))
                                   (:verifier . ,verifier)
                                   (:error . ,error-link))))))

(lofn:define-handler-fn (oauth-authenticate "/oauth/authenticate" nil ())
  (lofn:with-checked-parameters (action)
    (string-case:string-case (action)
      ("deny" "Not allowed")
      ("allow" (multiple-value-bind (token verifier url)
                   (north:oauth/authorize *server* (make-request hunchentoot:*request*))
                 (if url
                     (hunchentoot:redirect url)
                     (hunchentoot:redirect (format nil "/oauth/authorize?oauth_token=~a&verifier=~a"
                                                   (north:url-encode token) (north:url-encode verifier))))))
      (t
       (hunchentoot:redirect "/oauth/authorize?error=Invalid_action")))))

(lofn:define-handler-fn (oauth-access-token "/oauth/access-token" nil ())
  (multiple-value-bind (token secret)
      (north:oauth/access-token *server* (make-request hunchentoot:*request*))
    (north:alist->oauth-response `(("oauth_token" . ,token)
                                   ("oauth_token_secret" . ,secret)))))

(lofn:define-handler-fn (oauth-verify "/oauth/verify" nil ())
  (north:oauth/verify *server* (make-request hunchentoot:*request*))
  (north:alist->oauth-response `(("status" . "success"))))
