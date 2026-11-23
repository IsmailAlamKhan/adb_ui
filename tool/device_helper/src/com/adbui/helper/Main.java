package com.adbui.helper;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.drawable.Drawable;
import android.os.Looper;
import android.util.Base64;

import java.io.ByteArrayOutputStream;
import java.io.PrintStream;
import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.lang.reflect.Method;

/**
 * ADB UI's on-device helper (spec/features/app-icons.md). Started with app_process from
 * /data/local/tmp; prints app labels and icons that adb itself can't give.
 */
public final class Main {
    public static final int VERSION = 1;

    /** MATCH_UNINSTALLED_PACKAGES | MATCH_ANY_USER: also apps that live only in a work profile. */
    private static final int ANY_USER = 0x00002000 | 0x00400000;

    public static void main(String[] args) throws Exception {
        PrintStream out = new PrintStream(System.out, false, "UTF-8");
        if (args.length == 0 || args[0].equals("version")) {
            out.println("adbui-helper " + VERSION);
            out.flush();
            return;
        }
        PackageManager pm = systemContext().getPackageManager();
        switch (args[0]) {
            case "info": {
                // info <iconSize> <package>... -> package \t label \t base64 PNG (or "-")
                int size = Integer.parseInt(args[1]);
                for (int i = 2; i < args.length; i++) {
                    out.println(args[i] + "\t" + label(pm, args[i]) + "\t" + icon(pm, args[i], size));
                    out.flush();
                }
                break;
            }
            default:
                System.err.println("Unknown command: " + args[0]);
                System.exit(2);
        }
        out.flush();
    }

    private static String label(PackageManager pm, String pkg) {
        try {
            ApplicationInfo app = pm.getApplicationInfo(pkg, ANY_USER);
            return String.valueOf(app.loadLabel(pm)).replace('\t', ' ').replace('\n', ' ').trim();
        } catch (Throwable t) {
            return "";
        }
    }

    private static String icon(PackageManager pm, String pkg, int size) {
        try {
            ApplicationInfo app = pm.getApplicationInfo(pkg, ANY_USER);
            Drawable drawable = app.loadIcon(pm);
            if (drawable == null) return "-";
            Bitmap bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888);
            Canvas canvas = new Canvas(bitmap);
            drawable.setBounds(0, 0, size, size);
            drawable.draw(canvas);
            ByteArrayOutputStream bytes = new ByteArrayOutputStream();
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, bytes);
            bitmap.recycle();
            return Base64.encodeToString(bytes.toByteArray(), Base64.NO_WRAP);
        } catch (Throwable t) {
            return "-";
        }
    }

    /** A system Context outside an app process, the way scrcpy's server gets one. */
    private static Context systemContext() throws Exception {
        if (Looper.getMainLooper() == null) Looper.prepareMainLooper();
        Class<?> activityThreadClass = Class.forName("android.app.ActivityThread");
        Constructor<?> constructor = activityThreadClass.getDeclaredConstructor();
        constructor.setAccessible(true);
        Object activityThread = constructor.newInstance();
        Field current = activityThreadClass.getDeclaredField("sCurrentActivityThread");
        current.setAccessible(true);
        current.set(null, activityThread);
        Field systemThread = activityThreadClass.getDeclaredField("mSystemThread");
        systemThread.setAccessible(true);
        systemThread.setBoolean(activityThread, true);
        Method getSystemContext = activityThreadClass.getDeclaredMethod("getSystemContext");
        return (Context) getSystemContext.invoke(activityThread);
    }
}
