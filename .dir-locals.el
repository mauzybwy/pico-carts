(((lua-ts-mode pico8-mode)
  (line-spacing . 4)
  (tab-width . 2)
  (eval
   (lambda ()
     (mauzy/downcase-only-mode)
     (auto-fill-mode)
     (set-fill-column 50)
     (face-remap-add-relative 'default '(:family "PICO-8" :weight regular :height 180))))))
