package com.ibm.example;

import javax.jms.JMSConsumer;
import javax.jms.QueueBrowser;
import javax.jms.JMSContext;
import java.util.Enumeration;
import com.ibm.mq.jms.MQConnectionFactory;
import com.ibm.mq.jms.MQQueue;
import com.ibm.msg.client.wmq.WMQConstants;

public class readMQMessages 
{
    private static MQConnectionFactory mqConnFactory;
    private static JMSContext jmsCtxt;
    private static JMSConsumer jmsConsumer;
    private static MQQueue queue;
    private static boolean connected=false;
    
    private static void connectToMQ()
    {
        if (!connected)
        {
            try
            {
                mqConnFactory = new MQConnectionFactory();
                mqConnFactory.setTransportType(WMQConstants.WMQ_CM_CLIENT);
                mqConnFactory.setQueueManager("ordersnew1");
                mqConnFactory.setChannel("SYSTEM.DEF.SVRCONN");
                mqConnFactory.setHostName("student1-ordersnew1-ibm-mq.student1.svc");
                mqConnFactory.setPort(1414);
                mqConnFactory.setAppName("PaymentGateway");
                queue = new MQQueue("PAYMENT.REQ");
                queue.setMessageBodyStyle(WMQConstants.WMQ_MESSAGE_BODY_MQ);
                jmsCtxt = mqConnFactory.createContext(JMSContext.SESSION_TRANSACTED);
                jmsConsumer = jmsCtxt.createConsumer(queue);
                connected=true;
            }
            catch (Exception e)
            {
                e.printStackTrace();
            }

        }
    }

    public static void main(String[] args) 
    {
        try
        {
            connectToMQ();
            while(true)
            {
                if(shouldWeRead())
                {
                    jmsConsumer.receiveNoWait();
                }
                jmsCtxt.commit();
                Thread.sleep(100);
            }
        }
        catch(Exception e)
        {
            e.printStackTrace();
        }
    }

    public static boolean shouldWeRead() throws Exception
    {
        QueueBrowser browser = jmsCtxt.createBrowser(queue);
        Enumeration enumeration = browser.getEnumeration();
        int foundMsg=0;
        while(enumeration.hasMoreElements())
        {
            enumeration.nextElement();
            foundMsg++;
            if(foundMsg>5)
            {
                browser.close();
                return true;
            }
        }
        browser.close();
        return false;
    }
    
}
