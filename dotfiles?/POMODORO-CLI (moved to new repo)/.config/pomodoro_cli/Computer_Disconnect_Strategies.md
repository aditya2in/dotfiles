# Strategies for Disconnecting from Your Computer After 7 PM

This document outlines various strategies, from software-based to environmental, to help you enforce a strict cutoff time for computer usage, especially after 7 PM.

## Software-Based Strategies (More Restrictive)

These methods involve using software to limit or prevent computer access.

*   **Aggressive Screen Locking (Implemented):**
    *   **Mechanism:** Your current setup with `evening_lock.sh` and `hyprlock` will lock your screen every 60 seconds after 7 PM. This is a strong deterrent.
    *   **Pros:** Automated, highly disruptive, and difficult to ignore.
    *   **Cons:** Can be frustrating if you genuinely need brief access.

*   **Hard Shutdown/Reboot Script:**
    *   **Mechanism:** Modify the `evening_lock.sh` script (or a similar one) to initiate a system shutdown or reboot after a certain grace period (e.g., 5-10 minutes) past 7 PM.
    *   **Pros:** Guarantees you're off the computer. No way to bypass without restarting.
    *   **Cons:** Risk of losing unsaved work. Can be very disruptive if not planned for.

*   **Application Blockers:**
    *   **Mechanism:** Use dedicated software that blocks specific applications, websites, or categories of content after a set time.
    *   **Examples:** `coldturkey` (Linux/macOS/Windows), `freedom` (Cross-platform). These often have "hardcore" modes that make bypassing difficult.
    *   **Pros:** More granular control than a full screen lock; allows you to use the computer for non-work tasks if desired (e.g., media consumption).
    *   **Cons:** Requires initial setup and configuration. Might be bypassable with enough determination.

*   **Network Disabler:**
    *   **Mechanism:** A script that automatically disables your network interface (Wi-Fi or Ethernet) after 7 PM. Most work requires internet access.
    *   **Pros:** Highly effective for internet-dependent tasks.
    *   **Cons:** You might still be able to do offline work. Can be re-enabled if you know the commands.

*   **Parental Control Software (Self-Imposed):**
    *   **Mechanism:** Some Linux distributions offer built-in parental control features, or you can find third-party tools designed for this purpose. These can enforce time limits on overall computer usage.
    *   **Pros:** Comprehensive control over usage time.
    *   **Cons:** May require more complex setup.

## Environmental/Behavioral Strategies (Non-Software)

These methods involve physical actions or changes in routine to create barriers to computer use.

*   **Physical Disconnection:**
    *   **Unplug the Monitor:** The simplest and often most effective physical barrier. Physically unplug the video cable (HDMI/DisplayPort) from your monitor.
    *   **Unplug the Router/Modem:** If your work is heavily internet-dependent, physically unplugging your internet router or modem after 7 PM.
    *   **Pros:** Very difficult to bypass without conscious effort. Creates a clear physical boundary.
    *   **Cons:** Requires physical action. Might be inconvenient if others in your household need internet access.

*   **Scheduled Power Off (BIOS/UEFI):**
    *   **Mechanism:** Some computer BIOS/UEFI settings allow you to schedule a daily power-off time. This is a hardware-level hard stop.
    *   **Pros:** Fully automated and extremely effective.
    *   **Cons:** Requires access to BIOS settings. Not available on all systems.

*   **Change of Scenery/Activity:**
    *   **Mechanism:** Plan engaging activities *away* from your computer for after 7 PM. This shifts your focus and makes returning to the computer less appealing.
    *   **Examples:** Going for a walk/run, reading a physical book, spending time with family/friends, pursuing non-digital hobbies (cooking, drawing, playing an instrument).
    *   **Pros:** Addresses the root cause (desire to work/be on computer). Promotes a healthier work-life balance.
    *   **Cons:** Requires self-discipline and planning.

*   **Accountability Partner:**
    *   **Mechanism:** Inform a trusted friend, family member, or colleague about your goal. Ask them to hold you accountable. This could involve them checking in with you, or even physically removing your laptop/monitor cable at 7 PM.
    *   **Pros:** External motivation and support.
    *   **Cons:** Requires finding a willing and reliable partner.

*   **"Computer Goes to Bed" Routine:**
    *   **Mechanism:** Treat your computer like a child. At 7 PM, you "put it to bed" by shutting it down, putting it away (e.g., in a drawer or another room), and not touching it until the next morning.
    *   **Pros:** Creates a strong psychological boundary.
    *   **Cons:** Requires consistent adherence to the routine.

*   **Physical Timer/Alarm:**
    *   **Mechanism:** Set a loud, annoying physical alarm (not on your computer or phone) that goes off at 7 PM. Place it somewhere you have to physically get up and move away from your computer to turn it off.
    *   **Pros:** Disruptive and forces physical movement away from the screen.
    *   **Cons:** Can be ignored if you lack discipline.

By combining the aggressive screen locking you've implemented with one or more of these physical or behavioral strategies, you can significantly increase your success in disconnecting from your computer after 7 PM.
