package com.nora.nora_app

import android.app.Activity
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.view.Gravity
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.TextView
import android.view.View
import android.util.TypedValue
import android.text.Editable
import android.text.InputType
import android.text.TextWatcher

class BlockedAppActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.rgb(13, 16, 28)

        val background = GradientDrawable(
            GradientDrawable.Orientation.TL_BR,
            intArrayOf(Color.rgb(13, 16, 28), Color.rgb(31, 38, 73), Color.rgb(18, 25, 47)),
        )

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(28), dp(24), dp(28), dp(28))
            setBackground(background)
        }

        val brand = TextView(this).apply {
            text = "NORA  /  FOCUS GUARD"
            textSize = 12f
            letterSpacing = 0.16f
            setTextColor(Color.rgb(147, 161, 255))
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            gravity = Gravity.CENTER
        }

        val shield = TextView(this).apply {
            text = "N"
            textSize = 42f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            setBackground(GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                colors = intArrayOf(Color.rgb(55, 70, 255), Color.rgb(0, 190, 224))
            })
        }

        val title = TextView(this).apply {
            text = "Your focus is protected"
            textSize = 30f
            setTextColor(Color.WHITE)
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            gravity = Gravity.CENTER
        }
        val message = TextView(this).apply {
            text = "This distraction is paused while you work.\nYou are closer than you think."
            textSize = 16f
            setTextColor(Color.rgb(196, 202, 220))
            gravity = Gravity.CENTER
            setLineSpacing(4f, 1.1f)
        }

        val rule = View(this).apply {
            setBackgroundColor(Color.rgb(67, 78, 122))
        }

        val taskPrompt = TextView(this).apply {
            text = "Focus check\nWhat will you work on next?"
            textSize = 15f
            setTextColor(Color.rgb(224, 228, 242))
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            gravity = Gravity.CENTER
        }

        val intention = EditText(this).apply {
            hint = "Write one clear intention"
            setHintTextColor(Color.rgb(143, 153, 181))
            setTextColor(Color.WHITE)
            textSize = 16f
            inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_CAP_SENTENCES
            minLines = 1
            maxLines = 3
            gravity = Gravity.TOP or Gravity.START
            setPadding(dp(16), dp(14), dp(16), dp(14))
            setBackground(GradientDrawable().apply {
                cornerRadius = dp(16).toFloat()
                setColor(Color.rgb(38, 47, 82))
                setStroke(dp(1), Color.rgb(82, 96, 151))
            })
        }

        val home = Button(this).apply {
            text = "Return to Nora"
            textSize = 16f
            setTextColor(Color.WHITE)
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            isAllCaps = false
            setBackground(GradientDrawable().apply {
                cornerRadius = dp(18).toFloat()
                setColor(Color.rgb(48, 62, 235))
            })
            stateListAnimator = null
            minHeight = dp(56)
            setPadding(dp(20), 0, dp(20), 0)
            setOnClickListener {
                startActivity(IntentHelper.homeIntent())
                finish()
            }
        }

        home.isEnabled = false
        home.alpha = 0.45f
        intention.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(text: CharSequence?, start: Int, count: Int, after: Int) = Unit
            override fun onTextChanged(text: CharSequence?, start: Int, before: Int, count: Int) {
                val ready = (text?.trim()?.length ?: 0) >= 3
                home.isEnabled = ready
                home.alpha = if (ready) 1f else 0.45f
            }
            override fun afterTextChanged(editable: Editable?) = Unit
        })

        val hint = TextView(this).apply {
            text = "Focus sessions make room for what matters."
            textSize = 13f
            setTextColor(Color.rgb(143, 153, 181))
            gravity = Gravity.CENTER
        }

        root.addView(brand, centeredParams())
        root.addView(space(26))
        root.addView(shield, sizeParams(112))
        root.addView(space(30))
        root.addView(title, centeredParams())
        root.addView(space(14))
        root.addView(message, centeredParams())
        root.addView(space(22))
        root.addView(rule, centeredParams(LinearLayout.LayoutParams.MATCH_PARENT, 1))
        root.addView(space(22))
        root.addView(taskPrompt, centeredParams())
        root.addView(space(14))
        root.addView(intention, centeredParams(LinearLayout.LayoutParams.MATCH_PARENT, dp(78)))
        root.addView(space(18))
        root.addView(home, centeredParams())
        root.addView(space(18))
        root.addView(hint, centeredParams())
        setContentView(root)
    }

    private fun dp(value: Int): Int =
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value.toFloat(), resources.displayMetrics).toInt()

    private fun space(height: Int): View = View(this).apply {
        layoutParams = LinearLayout.LayoutParams(1, dp(height))
    }

    private fun centeredParams(): LinearLayout.LayoutParams =
        centeredParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT)

    private fun centeredParams(width: Int, height: Int): LinearLayout.LayoutParams =
        LinearLayout.LayoutParams(width, height).apply {
            gravity = Gravity.CENTER_HORIZONTAL
        }

    private fun sizeParams(size: Int): LinearLayout.LayoutParams =
        LinearLayout.LayoutParams(dp(size), dp(size)).apply {
            gravity = Gravity.CENTER_HORIZONTAL
        }

    companion object {
        const val BLOCKED_PACKAGE_EXTRA = "blocked_package"
    }
}

private object IntentHelper {
    fun homeIntent() = android.content.Intent(android.content.Intent.ACTION_MAIN).apply {
        addCategory(android.content.Intent.CATEGORY_HOME)
        addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
    }
}
