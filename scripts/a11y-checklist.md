# Accessibility PR Checklist

Use this manual checklist before approving UI changes.

1. **Contrast** – Verify text and icons meet WCAG AA using the [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/).
2. **Semantics** – Ensure interactive controls have labels and appropriate roles.
3. **Focus Order** – Tab through the screen; focus should follow the visual layout and remain visible.
4. **Text Scaling** – Increase system font size to 200% and confirm content remains usable.
5. **Hit Targets** – Confirm touch areas are at least 44×44 dp.
6. **Reduced Motion** – Enable the system's reduced-motion setting and ensure animations shorten or disable accordingly.
7. **Screen Readers** – Test with VoiceOver (macOS/iOS) or TalkBack (Android) to verify announcements and navigation.
