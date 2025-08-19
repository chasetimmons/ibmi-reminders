**free
//-------------------------------------------------------------------
// OBJECT:  CMT003R
// PURPOSE: Send out reminders
//
// AUTHOR: CTIMMONS     DATE CREATED: 07/28/2025
//
//-------------------------------------------------------------------
// TODO:
//-------------------------------------------------------------------
// - email handling is not very flexible
// - how to factor in time?
// - currently just using dfu to add reminders
// - add a job scheduler entry to run at least once daily
//-------------------------------------------------------------------
// MODIFICATIONS:
//-------------------------------------------------------------------
// DATE   MOD   AUTHOR     TEXT
// xxxxxx xxx   xxxxxx     xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
//-------------------------------------------------------------------

//*******************************************************************
// control options                                                  *
//*******************************************************************
ctl-opt debug option(*srcstmt:*nodebugio) dftactgrp(*no) actgrp(*new) ;

/include cmtlib/qcpysrc,psds

//*******************************************************************
// declarations                                                     *
//*******************************************************************
dcl-s today date(*iso) ;     // todays date
dcl-s command varchar(500) ; // command string
dcl-s email char(50) ;       // email string

// define a data structure that matches the table columns
dcl-ds rem extname('REMINDERS') qualified end-ds ;

// constants
dcl-c DOMAIN  '@email.com' ;        // email domain
dcl-c QSYSOPR 'support@email.com' ; // qsysopr email

// send_message procedure interface
dcl-pr send_message ;
    muser char(10)  ;
    mmesg char(50) ;
end-pr ;

// send_email procedure interface
dcl-pr send_email ;
    euser char(50) ;
    emesg char(50) ;
end-pr ;

//*******************************************************************
// main procedure                                                   *
//*******************************************************************
// ---
// begin processing loop
// ---

// set the date to today to check for today's reminders
exec sql set :today = CURRENT_DATE ;

// declare cursor for reminders file
// if null, set to blank using value()
exec sql
    declare c1 cursor for
        select rem_nbr,
               rem_dat,
               rem_tim,
               rem_txt,
               rem_us1,
               value(rem_us2,''),
               value(rem_eml,''),
               value(rem_com,'')
        from cmtlib.reminders ;

// open the cursor
exec sql
    open c1 ;

// loop until there are no more rows to fetch
dow sqlcode = 0 ;

    // read the next record
    exec sql
        fetch next from c1 into :rem ;

    // if successful
    if sqlcode = 0 ;

        // check for todays date and if not marked completed
        if rem.rem_dat = today and rem.rem_com = *blank ;

            // send the message text to first user
            send_message(rem.rem_us1:rem.rem_txt) ;

            // send the message text via email to first user, if applicable
            if rem.rem_eml <> *blank ;
                // handle qsysopr emails
                if rem.rem_us1 = 'QSYSOPR' ;
                    email = QSYSOPR ;
                else ;
                    email = %trim(rem.rem_us1) + DOMAIN ;
                endif ;

                send_email(email:rem.rem_txt) ;
            endif ;

            // send the message text to second user, if applicable
            if rem.rem_us2 <> *blank ;
                send_message(rem.rem_us2:rem.rem_txt) ;
            endif ;


            // send the message text via email to second user, if applicable
            if (rem.rem_us2 <> *blank) and (rem.rem_eml <> *blank) ;
                // handle qsysopr emails
                if rem.rem_us2 = 'QSYSOPR' ;
                    email = QSYSOPR ;
                else ;
                    email = %trim(rem.rem_us2) + DOMAIN ;
                endif ;

                send_email(email:rem.rem_txt) ;
            endif ;

            // mark as completed
            exec sql
                update cmtlib.reminders
                set rem_com = 'X'
                where rem_nbr = :rem.rem_nbr
                with nc ;

        endif ;

    endif ;

enddo ;

// close the cursor
exec sql close c1 ;

//*******************************************************************
// program end                                                      *
//*******************************************************************
*inlr = *on ;
//return ;

//*******************************************************************
// send_message procedure                                           *
//*******************************************************************
dcl-proc send_message ;
    dcl-pi *n ;
        userm char(10) ;
        mesgm char(50) ;
    end-pi ;

    command = 'SNDMSG MSG(''' + %trim(mesgm) + ''') TOMSGQ(' + %trim(userm) + ')' ;
    exec sql call qsys2.qcmdexc(:command) ;

    return ;
end-proc ;

//*******************************************************************
// send_email procedure                                             *
//*******************************************************************
dcl-proc send_email ;
    dcl-pi *n ;
        usere char(50) ;
        mesge char(50) ;
    end-pi ;

    command = 'SNDSMTPEMM RCP((''' + %trim(usere) + ''')) +
               SUBJECT(''REMINDER'') +
               NOTE(''' + %trim(mesge) + ''')' ;
    exec sql call qsys2.qcmdexc(:command) ;

    return ;
end-proc ;
