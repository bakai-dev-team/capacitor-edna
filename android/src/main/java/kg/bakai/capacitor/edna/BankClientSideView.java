package kg.bakai.capacitor.edna;

import android.content.Context;
import android.content.ContextWrapper;
import android.graphics.*;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.Animatable;
import android.util.AttributeSet;
import android.view.*;
import android.widget.TextView;
import android.widget.ImageView;

/** Draws avatar/time beside either message direction; Edna owns delivery/read state. */
public final class BankClientSideView extends View implements ViewTreeObserver.OnPreDrawListener {
    private final Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final float dp;
    private View row;
    private TextView time;
    private Bitmap avatar;
    private ImageView operator;
    private final Bitmap operatorFallback;
    private boolean incoming;
    private Animatable sendingAnimation;
    private String signature = "";
    public BankClientSideView(Context context, AttributeSet attrs) {
        super(context, attrs); dp=getResources().getDisplayMetrics().density;
        operatorFallback=BitmapFactory.decodeResource(getResources(), R.drawable.bakai_edna_operator_avatar);
        Context owner=context;
        while(owner instanceof ContextWrapper && !(owner instanceof EdnaChatActivity)) owner=((ContextWrapper)owner).getBaseContext();
        if(owner instanceof EdnaChatActivity) avatar=((EdnaChatActivity)owner).getClientAvatar();
    }
    @Override protected void onAttachedToWindow() {
        super.onAttachedToWindow(); row=(View)getParent();
        incoming = "incoming".equals(getTag());
        operator = row.findViewById(edna.chatcenter.ui.R.id.consultAvatar);
        if (operator == null) operator = row.findViewById(edna.chatcenter.ui.R.id.consult_avatar);
        getViewTreeObserver().addOnPreDrawListener(this);
    }
    @Override public boolean onPreDraw() {
        TextView normal=row.findViewById(edna.chatcenter.ui.R.id.timeStamp);
        TextView image=row.findViewById(edna.chatcenter.ui.R.id.imageTimeStamp);
        time=normal!=null && normal.isShown()?normal:image!=null && image.isShown()?image:null;
        TextView file=row.findViewById(edna.chatcenter.ui.R.id.fileTimeStamp);
        if(time==null && file!=null && file.isShown()) time=file;
        TextView sent=row.findViewById(edna.chatcenter.ui.R.id.sendAt);
        if(time==null && sent!=null && sent.isShown()) time=sent;
        if(sent!=null) sent.setAlpha(0);
        if(file!=null) file.setAlpha(0);
        if(incoming && operator!=null) {
            operator.setAlpha(0);
            operator.setBackground(null);
            operator.setImageTintList(null);
        }
        TextView message=row.findViewById(edna.chatcenter.ui.R.id.text);
        if(message!=null) {
            if(message.getTypeface()!=null && message.getTypeface().isBold()) message.setTypeface(Typeface.create(message.getTypeface(), Typeface.NORMAL));
            if(message.getPaint().isFakeBoldText()) { message.getPaint().setFakeBoldText(false); message.invalidate(); }
        }
        if(normal!=null) normal.setAlpha(0); if(image!=null) image.setAlpha(0);
        // Invalidate only this small rail when the SDK redraws a visible row.
        Drawable drawable=time==null?null:time.getCompoundDrawablesRelative()[2];
        String next=time==null?"":time.getText()+":"+time.getCurrentTextColor()+":"+(drawable==null?"":drawable.getConstantState());
        if(incoming && operator!=null) next += ":" + operator.getDrawable();
        if(!signature.equals(next)) { signature=next; invalidate(); }
        return true;
    }
    @Override protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        // Align the photo to the bubble-facing edge of the metadata rail.
        float centerX=incoming ? getWidth()-11*dp : 11*dp;
        Drawable source=incoming && operator!=null ? operator.getDrawable() : null;
        Bitmap photo=incoming ? operatorFallback : avatar;
        canvas.save();
        Path circle=new Path(); circle.addCircle(centerX,11*dp,11*dp,Path.Direction.CW);
        canvas.clipPath(circle);
        if(incoming) {
            paint.setColor(Color.WHITE); canvas.drawCircle(centerX,11*dp,11*dp,paint);
        }
        if(source!=null && source.getIntrinsicWidth()>1 && source.getIntrinsicHeight()>1) {
            // Never draw the SDK's shared/tinted drawable directly: its bounds and
            // tint also belong to the asynchronous image loader.
            Drawable.ConstantState state=source.getConstantState();
            Drawable icon=state==null ? null : state.newDrawable(getResources()).mutate();
            if(icon!=null) {
                icon.setTintList(null); icon.clearColorFilter(); icon.setAlpha(255);
                icon.setBounds(Math.round(centerX-11*dp),0,Math.round(centerX+11*dp),Math.round(22*dp));
                icon.draw(canvas);
            } else if(photo!=null) canvas.drawBitmap(photo,null,new RectF(centerX-11*dp,0,centerX+11*dp,22*dp),paint);
        } else if(photo!=null) {
            canvas.drawBitmap(photo,null,new RectF(centerX-11*dp,0,centerX+11*dp,22*dp),paint);
        }
        canvas.restore();
        if(time==null) {
            if (sendingAnimation != null) sendingAnimation.stop();
            sendingAnimation = null;
            return;
        }
        paint.setTextSize(8*getResources().getDisplayMetrics().scaledDensity); paint.setColor(time.getCurrentTextColor());
        String value=time.getText().toString(); Drawable status=incoming?null:time.getCompoundDrawablesRelative()[2];
        if(status==null && !incoming) status=time.getCompoundDrawables()[2];
        float width=paint.measureText(value)+(status==null?0:16*dp), x=(getWidth()-width)/2;
        canvas.drawText(value,x,33*dp,paint);
        Animatable animation = status instanceof Animatable ? (Animatable) status : null;
        if (sendingAnimation != animation) {
            if (sendingAnimation != null) sendingAnimation.stop();
            sendingAnimation = animation;
        }
        if (sendingAnimation != null) {
            if (!sendingAnimation.isRunning()) sendingAnimation.start();
            postInvalidateOnAnimation();
        }
        if(status!=null) {
            Rect original=new Rect(status.getBounds());
            int left=Math.round(x+paint.measureText(value)+3*dp);
            status.setBounds(left,Math.round(23*dp),left+Math.round(13*dp),Math.round(36*dp)); status.draw(canvas); status.setBounds(original);
        }
    }
    @Override protected void onDetachedFromWindow() {
        if(getViewTreeObserver().isAlive())getViewTreeObserver().removeOnPreDrawListener(this);
        if (sendingAnimation != null) sendingAnimation.stop();
        sendingAnimation = null;
        row=null;time=null;super.onDetachedFromWindow();
    }
}
